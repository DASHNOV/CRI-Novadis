using Microsoft.EntityFrameworkCore;
using NovadisApi.Data;
using NovadisApi.Models;
using NovadisApi.Models.DTOs;
using NovadisApi.Services.Email;
using System.Security.Cryptography;

namespace NovadisApi.Services.Auth;

public sealed class AuthService : IAuthService
{
    private readonly NovadisDbContext _context;
    private readonly ICodeGeneratorService _codeGenerator;
    private readonly IJwtService _jwtService;
    private readonly IEmailService _emailService;
    private readonly ILogger<AuthService> _logger;
    private readonly IConfiguration _configuration;

    public AuthService(
        NovadisDbContext context,
        ICodeGeneratorService codeGenerator,
        IJwtService jwtService,
        IEmailService emailService,
        ILogger<AuthService> logger,
        IConfiguration configuration)
    {
        _context = context;
        _codeGenerator = codeGenerator;
        _jwtService = jwtService;
        _emailService = emailService;
        _logger = logger;
        _configuration = configuration;
    }

    public async Task<AuthResult<LoginResponse>> RequestLoginCodeAsync(LoginRequestDto request, CancellationToken ct = default)
    {
        _logger.LogInformation("Login attempt for email: {Email}", request.Email);

        var user = await _context.Users
            .FirstOrDefaultAsync(u => u.Email.ToLower() == request.Email.ToLower(), ct);

        if (user == null || !user.CanSignIn())
        {
            _logger.LogWarning("Login failed: User not found, inactive or unknown role - {Email} (role: {Role})",
                request.Email, user?.Role);
            return AuthResult<LoginResponse>.Failure(
                AuthErrorCode.UserNotFound,
                "Aucun compte associé à cette adresse email.");
        }

        // Pas de nouveau code pendant le verrouillage : il serait refusé à la saisie,
        // et l'utilisateur croirait à un code erroné.
        var lockout = await GetLockoutAsync(user.Email, ct);
        if (lockout != null)
            return AuthResult<LoginResponse>.Failure(AuthErrorCode.AccountLocked, lockout);

        var code = _codeGenerator.GenerateCode(6);
        var codeHash = _codeGenerator.HashCode(code);
        var codeExpiry = _configuration.GetValue<int>("Auth:CodeExpiryMinutes", 10);

        var authAttempt = new AuthAttempt
        {
            Email = user.Email,
            CodeHash = codeHash,
            ExpiresAt = DateTime.UtcNow.AddMinutes(codeExpiry),
            IpAddress = request.IpAddress,
#if DEBUG
            PlainCode = code
#endif
        };

        _context.AuthAttempts.Add(authAttempt);
        await _context.SaveChangesAsync(ct);

#if DEBUG
        _logger.LogInformation("🔐 [DEV] Code de connexion pour {Email}: {Code}", request.Email, code);
#endif

        try
        {
            var emailBody = BuildOtpEmail(user.FirstName, code, codeExpiry);
            await _emailService.SendEmailAsync(user.Email, "Code de connexion Novadis CRI", emailBody);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Email delivery failed for {Email}", request.Email);
            return AuthResult<LoginResponse>.Failure(
                AuthErrorCode.EmailDeliveryFailed,
                "Erreur lors de l'envoi de l'email. Veuillez réessayer plus tard.");
        }

        _context.AuditLogs.Add(new AuditLog
        {
            UserId = user.Id,
            Action = "LOGIN_REQUEST",
            EntityType = "Auth",
            Details = $"Code de connexion envoyé à {user.Email}",
            IpAddress = request.IpAddress
        });
        await _context.SaveChangesAsync(CancellationToken.None);

        _logger.LogInformation("Login code sent successfully to {Email}", request.Email);
        return AuthResult<LoginResponse>.Success(new LoginResponse(codeExpiry));
    }

    public async Task<AuthResult<AuthResponseDto>> VerifyCodeAsync(VerifyCodeRequestDto request, CancellationToken ct = default)
    {
        _logger.LogInformation("Code verification attempt for {Email}", request.Email);

        var user = await _context.Users
            .FirstOrDefaultAsync(u => u.Email.ToLower() == request.Email.ToLower(), ct);

        if (user == null || !user.CanSignIn())
            return AuthResult<AuthResponseDto>.Failure(AuthErrorCode.UserNotFound, "Email ou code invalide.");

        // Avant toute vérification : un code correct est refusé pendant le verrouillage,
        // sans quoi l'essai exhaustif resterait possible.
        var lockout = await GetLockoutAsync(user.Email, ct);
        if (lockout != null)
            return AuthResult<AuthResponseDto>.Failure(AuthErrorCode.AccountLocked, lockout);

        var authAttempt = await _context.AuthAttempts
            .Where(a => a.Email.ToLower() == request.Email.ToLower()
                && !a.IsUsed
                && a.ExpiresAt > DateTime.UtcNow)
            .OrderByDescending(a => a.CreatedAt)
            .FirstOrDefaultAsync(ct);

        if (authAttempt == null)
        {
            _logger.LogWarning("No valid auth attempt found for {Email}", request.Email);
            return AuthResult<AuthResponseDto>.Failure(
                AuthErrorCode.CodeExpired,
                "Code expiré ou invalide. Veuillez demander un nouveau code.");
        }

        if (!_codeGenerator.VerifyCode(request.Code, authAttempt.CodeHash))
        {
            authAttempt.FailedAttempts++;
            await _context.SaveChangesAsync(ct);
            _logger.LogWarning("Invalid code attempt for {Email} - Attempt {Count}",
                request.Email, authAttempt.FailedAttempts);
            return AuthResult<AuthResponseDto>.Failure(AuthErrorCode.InvalidCode, "Code invalide.");
        }

        authAttempt.IsUsed = true;

        // Remise à zéro : des échecs antérieurs à une connexion réussie ne doivent pas
        // verrouiller le compte après coup.
        var failedAttempts = await _context.AuthAttempts
            .Where(a => a.Email.ToLower() == user.Email.ToLower() && a.FailedAttempts > 0)
            .ToListAsync(ct);
        foreach (var attempt in failedAttempts)
            attempt.FailedAttempts = 0;

        await _context.SaveChangesAsync(ct);

        var response = await IssueTokensAsync(user, request.IpAddress, request.DeviceInfo, generateTrustedDevice: true, ct);

        _context.AuditLogs.Add(new AuditLog
        {
            UserId = user.Id,
            Action = "LOGIN_SUCCESS",
            EntityType = "Auth",
            Details = $"Connexion réussie pour {user.Email}",
            IpAddress = request.IpAddress
        });
        await _context.SaveChangesAsync(ct);

        _logger.LogInformation("User {Email} logged in successfully", user.Email);
        return AuthResult<AuthResponseDto>.Success(response);
    }

    /// <summary>
    /// Verrouillage OTP : au-delà de <c>Auth:MaxFailedAttempts</c> codes erronés sur la
    /// fenêtre <c>Auth:LockoutDurationMinutes</c>, toutes demandes confondues, l'e-mail est
    /// verrouillé. Renvoie le message à afficher, ou <c>null</c> si le compte est libre.
    /// Porte sur l'e-mail et non sur l'IP : un tiers peut donc verrouiller un compte
    /// volontairement — compromis assumé (fenêtre courte, message explicite).
    /// </summary>
    private async Task<string?> GetLockoutAsync(string email, CancellationToken ct)
    {
        var maxAttempts = _configuration.GetValue("Auth:MaxFailedAttempts", 5);
        var lockoutMinutes = _configuration.GetValue("Auth:LockoutDurationMinutes", 30);
        var windowStart = DateTime.UtcNow.AddMinutes(-lockoutMinutes);

        var recentFailures = await _context.AuthAttempts
            .Where(a => a.Email.ToLower() == email.ToLower() && a.CreatedAt >= windowStart)
            .SumAsync(a => a.FailedAttempts, ct);

        if (recentFailures < maxAttempts)
            return null;

        _logger.LogWarning("Account locked for {Email} ({Count} failed attempts)", email, recentFailures);
        return $"Trop de tentatives. Réessayez dans {lockoutMinutes} minutes.";
    }

    public async Task<AuthResult<AuthResponseDto>> RefreshTokenAsync(RefreshTokenRequestDto request, CancellationToken ct = default)
    {
        _logger.LogInformation("Token refresh attempt");

        var userToken = await _context.UserTokens
            .Include(t => t.User)
            .FirstOrDefaultAsync(t => t.RefreshToken == request.RefreshToken
                && !t.IsRevoked
                && t.ExpiresAt > DateTime.UtcNow, ct);

        if (userToken == null)
        {
            _logger.LogWarning("Invalid or expired refresh token");
            return AuthResult<AuthResponseDto>.Failure(AuthErrorCode.InvalidToken, "Token invalide ou expiré.");
        }

        var user = userToken.User!;
        if (!user.CanSignIn())
        {
            _logger.LogWarning("User {Email} is inactive or has unknown role {Role}", user.Email, user.Role);
            return AuthResult<AuthResponseDto>.Failure(AuthErrorCode.AccountInactive, "Compte désactivé.");
        }

        userToken.IsRevoked = true;

        var response = await IssueTokensAsync(user, request.IpAddress, request.DeviceInfo, generateTrustedDevice: false, ct);
        await _context.SaveChangesAsync(ct);

        _logger.LogInformation("Token refreshed successfully for user {Email}", user.Email);
        return AuthResult<AuthResponseDto>.Success(response);
    }

    public async Task<AuthResult<bool>> LogoutAsync(Guid userId, RefreshTokenRequestDto request, CancellationToken ct = default)
    {
        _logger.LogInformation("Logout attempt for user {UserId}", userId);

        var userToken = await _context.UserTokens
            .FirstOrDefaultAsync(t => t.RefreshToken == request.RefreshToken && !t.IsRevoked, ct);

        if (userToken != null)
        {
            userToken.IsRevoked = true;
            await _context.SaveChangesAsync(ct);
        }

        _context.AuditLogs.Add(new AuditLog
        {
            UserId = userId,
            Action = "LOGOUT",
            EntityType = "Auth",
            Details = "Déconnexion réussie",
            IpAddress = request.IpAddress
        });
        await _context.SaveChangesAsync(ct);

        _logger.LogInformation("User {UserId} logged out successfully", userId);
        return AuthResult<bool>.Success(true);
    }

    public async Task<AuthResult<UserDto>> GetCurrentUserAsync(Guid userId, CancellationToken ct = default)
    {
        var user = await _context.Users.FindAsync(new object[] { userId }, ct);

        if (user == null || !user.CanSignIn())
            return AuthResult<UserDto>.Failure(AuthErrorCode.UserNotFound, "Utilisateur introuvable");

        return AuthResult<UserDto>.Success(MapUser(user));
    }

    public async Task<AuthResult<AuthResponseDto>> VerifyTrustedDeviceAsync(VerifyDeviceRequestDto request, CancellationToken ct = default)
    {
        _logger.LogInformation("Trusted device login attempt for {Email}", request.Email);

        var userToken = await _context.UserTokens
            .Include(t => t.User)
            .FirstOrDefaultAsync(t =>
                t.TrustedDeviceToken == request.TrustedDeviceToken
                && t.User!.Email.ToLower() == request.Email.ToLower()
                && !t.IsRevoked
                && t.ExpiresAt > DateTime.UtcNow, ct);

        if (userToken == null)
        {
            _logger.LogWarning("Trusted device not recognized for {Email}", request.Email);
            return AuthResult<AuthResponseDto>.Failure(
                AuthErrorCode.DeviceNotRecognized,
                "Appareil non reconnu ou session expirée.");
        }

        var user = userToken.User!;
        if (!user.CanSignIn())
            return AuthResult<AuthResponseDto>.Failure(AuthErrorCode.AccountInactive, "Compte désactivé.");

        userToken.IsRevoked = true;
        userToken.RevokedReason = "trusted_device_rotation";

        var response = await IssueTokensAsync(
            user,
            request.IpAddress,
            request.DeviceInfo ?? userToken.DeviceInfo,
            generateTrustedDevice: true,
            ct);

        _context.AuditLogs.Add(new AuditLog
        {
            UserId = user.Id,
            Action = "LOGIN_TRUSTED_DEVICE",
            EntityType = "Auth",
            Details = $"Connexion via appareil de confiance pour {user.Email}",
            IpAddress = request.IpAddress
        });
        await _context.SaveChangesAsync(ct);

        _logger.LogInformation("Trusted device login successful for {Email}", user.Email);
        return AuthResult<AuthResponseDto>.Success(response);
    }

    private async Task<AuthResponseDto> IssueTokensAsync(
        User user,
        string? ipAddress,
        string? deviceInfo,
        bool generateTrustedDevice,
        CancellationToken ct)
    {
        var accessToken = _jwtService.GenerateAccessToken(user);
        var refreshToken = _jwtService.GenerateRefreshToken();
        var refreshExpiry = _configuration.GetValue<int>("Jwt:RefreshExpiryDays", 7);
        var expiryMinutes = _configuration.GetValue<int>("Jwt:ExpiryMinutes", 60);

        var trustedDeviceToken = generateTrustedDevice
            ? Convert.ToBase64String(RandomNumberGenerator.GetBytes(48))
            : null;

        var newUserToken = new UserToken
        {
            UserId = user.Id,
            RefreshToken = refreshToken,
            ExpiresAt = DateTime.UtcNow.AddDays(refreshExpiry),
            DeviceInfo = deviceInfo,
            IpAddress = ipAddress,
            TrustedDeviceToken = trustedDeviceToken
        };

        _context.UserTokens.Add(newUserToken);
        user.LastLoginAt = DateTime.UtcNow;
        await _context.SaveChangesAsync(ct);

        return new AuthResponseDto
        {
            AccessToken = accessToken,
            RefreshToken = refreshToken,
            ExpiresAt = DateTime.UtcNow.AddMinutes(expiryMinutes),
            TrustedDeviceToken = trustedDeviceToken,
            User = MapUser(user)
        };
    }

    private static UserDto MapUser(User user) => new()
    {
        Id = user.Id,
        Email = user.Email,
        FirstName = user.FirstName,
        LastName = user.LastName,
        Role = UserRoleExtensions.Normalize(user.Role),
        IsActive = user.IsActive,
        LastLoginAt = user.LastLoginAt
    };

    private static string BuildOtpEmail(string firstName, string code, int codeExpiry) => $@"
        <html>
        <body style='font-family: Arial, sans-serif;'>
            <div style='max-width: 600px; margin: 0 auto; padding: 20px;'>
                <h2 style='color: #2563eb;'>Connexion à Novadis CRI</h2>
                <p>Bonjour {firstName},</p>
                <p>Voici votre code de vérification pour vous connecter :</p>
                <div style='background: #f3f4f6; padding: 20px; border-radius: 8px; text-align: center; margin: 20px 0;'>
                    <h1 style='color: #1f2937; font-size: 36px; letter-spacing: 8px; margin: 0;'>{code}</h1>
                </div>
                <p style='color: #6b7280;'>Ce code expire dans {codeExpiry} minutes.</p>
                <p style='color: #6b7280; font-size: 12px;'>Si vous n'avez pas demandé ce code, ignorez cet email.</p>
                <hr style='border: none; border-top: 1px solid #e5e7eb; margin: 30px 0;'>
                <p style='color: #9ca3af; font-size: 12px;'>© {DateTime.UtcNow.Year} Novadis - Tous droits réservés</p>
            </div>
        </body>
        </html>";
}
