using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using NovadisApi.Data;
using NovadisApi.Models.DTOs;
using NovadisApi.Services.Auth;
using System.Security.Claims;

namespace NovadisApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly IAuthService _authService;
        private readonly NovadisDbContext _context;
        private readonly ILogger<AuthController> _logger;

        public AuthController(
            IAuthService authService,
            NovadisDbContext context,
            ILogger<AuthController> logger)
        {
            _authService = authService;
            _context = context;
            _logger = logger;
        }

        /// <summary>📧 POST /api/auth/login - Demander un code de connexion</summary>
        [HttpPost("login")]
        [AllowAnonymous]
        [EnableRateLimiting("AuthPolicy")]
        public async Task<ActionResult<ApiResponse<object>>> Login([FromBody] LoginRequestDto request, CancellationToken ct)
        {
            var ip = request.IpAddress ?? HttpContext.Connection.RemoteIpAddress?.ToString();
            var enriched = new LoginRequestDto { Email = request.Email, IpAddress = ip, DeviceInfo = request.DeviceInfo };

            var result = await _authService.RequestLoginCodeAsync(enriched, ct);
            if (!result.IsSuccess)
                return MapErrorObject(result.ErrorCode, result.ErrorMessage);

            return Ok(ApiResponse<object>.SuccessResponse(
                new { expiresIn = result.Value!.ExpiresIn },
                "Un code de vérification a été envoyé à votre adresse email."));
        }

        /// <summary>✅ POST /api/auth/verify - Vérifier le code et obtenir un token JWT</summary>
        [HttpPost("verify")]
        [AllowAnonymous]
        [EnableRateLimiting("AuthPolicy")]
        public async Task<ActionResult<ApiResponse<AuthResponseDto>>> VerifyCode([FromBody] VerifyCodeRequestDto request, CancellationToken ct)
        {
            var ip = request.IpAddress ?? HttpContext.Connection.RemoteIpAddress?.ToString();
            var enriched = new VerifyCodeRequestDto
            {
                Email = request.Email, Code = request.Code, IpAddress = ip, DeviceInfo = request.DeviceInfo
            };

            var result = await _authService.VerifyCodeAsync(enriched, ct);
            if (!result.IsSuccess) return MapError<AuthResponseDto>(result);

            return Ok(ApiResponse<AuthResponseDto>.SuccessResponse(result.Value!, "Connexion réussie"));
        }

        /// <summary>🔄 POST /api/auth/refresh - Rafraîchir le token d'accès</summary>
        [HttpPost("refresh")]
        [AllowAnonymous]
        [EnableRateLimiting("AuthPolicy")]
        public async Task<ActionResult<ApiResponse<AuthResponseDto>>> RefreshToken([FromBody] RefreshTokenRequestDto request, CancellationToken ct)
        {
            var ip = request.IpAddress ?? HttpContext.Connection.RemoteIpAddress?.ToString();
            var enriched = new RefreshTokenRequestDto
            {
                RefreshToken = request.RefreshToken, IpAddress = ip, DeviceInfo = request.DeviceInfo
            };

            var result = await _authService.RefreshTokenAsync(enriched, ct);
            if (!result.IsSuccess) return MapError<AuthResponseDto>(result);

            return Ok(ApiResponse<AuthResponseDto>.SuccessResponse(result.Value!, "Token rafraîchi avec succès"));
        }

        /// <summary>🚪 POST /api/auth/logout - Se déconnecter (révoquer le refresh token)</summary>
        [HttpPost("logout")]
        [Authorize]
        public async Task<ActionResult<ApiResponse<object>>> Logout([FromBody] RefreshTokenRequestDto request, CancellationToken ct)
        {
            if (!TryGetUserId(out var userId))
                return Unauthorized(ApiResponse<object>.ErrorResponse("Token invalide"));

            await _authService.LogoutAsync(userId, request, ct);
            return Ok(ApiResponse<object>.SuccessResponse(null!, "Déconnexion réussie"));
        }

        /// <summary>👤 GET /api/auth/me - Récupérer les informations de l'utilisateur connecté</summary>
        [HttpGet("me")]
        [Authorize]
        public async Task<ActionResult<ApiResponse<UserDto>>> GetCurrentUser(CancellationToken ct)
        {
            if (!TryGetUserId(out var userId))
                return Unauthorized(ApiResponse<UserDto>.ErrorResponse("Token invalide"));

            var result = await _authService.GetCurrentUserAsync(userId, ct);
            if (!result.IsSuccess) return MapError<UserDto>(result);

            return Ok(ApiResponse<UserDto>.SuccessResponse(result.Value!));
        }

        /// <summary>📱 POST /api/auth/verify-device - Connexion via appareil de confiance (skip OTP)</summary>
        [HttpPost("verify-device")]
        [AllowAnonymous]
        [EnableRateLimiting("AuthPolicy")]
        public async Task<ActionResult<ApiResponse<AuthResponseDto>>> VerifyDevice([FromBody] VerifyDeviceRequestDto request, CancellationToken ct)
        {
            var ip = request.IpAddress ?? HttpContext.Connection.RemoteIpAddress?.ToString();
            var enriched = new VerifyDeviceRequestDto
            {
                Email = request.Email,
                TrustedDeviceToken = request.TrustedDeviceToken,
                DeviceInfo = request.DeviceInfo,
                IpAddress = ip
            };

            var result = await _authService.VerifyTrustedDeviceAsync(enriched, ct);
            if (!result.IsSuccess) return MapError<AuthResponseDto>(result);

            return Ok(ApiResponse<AuthResponseDto>.SuccessResponse(result.Value!, "Connexion réussie"));
        }

        /// <summary>
        /// 🔧 GET /api/auth/dev/get-code/{email} - [DEV ONLY] Récupérer le dernier code généré
        /// ⚠️ À SUPPRIMER EN PRODUCTION
        /// </summary>
        [HttpGet("dev/get-code/{email}")]
        [AllowAnonymous]
#if !DEBUG
        [ApiExplorerSettings(IgnoreApi = true)]
#endif
        public async Task<ActionResult<ApiResponse<object>>> GetLastCode(string email, CancellationToken ct)
        {
#if !DEBUG
            return NotFound();
#else
            _logger.LogWarning("⚠️ DEV ENDPOINT CALLED: get-code for {Email}", email);

            var lastAttempt = await _context.AuthAttempts
                .Where(a => a.Email.ToLower() == email.ToLower()
                    && !a.IsUsed
                    && a.ExpiresAt > DateTime.UtcNow)
                .OrderByDescending(a => a.CreatedAt)
                .FirstOrDefaultAsync(ct);

            if (lastAttempt == null)
            {
                return NotFound(ApiResponse<object>.ErrorResponse(
                    "Aucun code actif trouvé. Demandez d'abord un code via /api/auth/login"));
            }

            return Ok(ApiResponse<object>.SuccessResponse(
                new
                {
                    email = lastAttempt.Email,
                    code = lastAttempt.PlainCode,
                    expiresAt = lastAttempt.ExpiresAt,
                    expiresIn = (int)(lastAttempt.ExpiresAt - DateTime.UtcNow).TotalMinutes,
                    createdAt = lastAttempt.CreatedAt,
                    warning = "⚠️ Cet endpoint est disponible uniquement en développement"
                },
                "Code récupéré (DEV MODE)"));
#endif
        }

        // ───────── helpers ─────────

        private bool TryGetUserId(out Guid userId)
        {
            userId = Guid.Empty;
            var raw = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            return !string.IsNullOrEmpty(raw) && Guid.TryParse(raw, out userId);
        }

        private ActionResult<ApiResponse<T>> MapError<T>(AuthResult<T> result)
        {
            var response = ApiResponse<T>.ErrorResponse(result.ErrorMessage ?? "Une erreur est survenue.");
            return ToActionResult(result.ErrorCode, response);
        }

        private ActionResult<ApiResponse<object>> MapErrorObject(AuthErrorCode code, string? message)
        {
            var response = ApiResponse<object>.ErrorResponse(message ?? "Une erreur est survenue.");
            return ToActionResult(code, response);
        }

        private ActionResult<ApiResponse<T>> ToActionResult<T>(AuthErrorCode code, ApiResponse<T> response) =>
            code switch
            {
                AuthErrorCode.UserNotFound => BadRequest(response),
                AuthErrorCode.InvalidCode => Unauthorized(response),
                AuthErrorCode.CodeExpired => Unauthorized(response),
                AuthErrorCode.InvalidToken => Unauthorized(response),
                AuthErrorCode.AccountInactive => Unauthorized(response),
                AuthErrorCode.DeviceNotRecognized => Unauthorized(response),
                AuthErrorCode.AccountLocked => StatusCode(StatusCodes.Status429TooManyRequests, response),
                AuthErrorCode.EmailDeliveryFailed => StatusCode(500, response),
                _ => StatusCode(500, response)
            };
    }
}
