using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NovadisApi.Data;
using NovadisApi.Models;
using NovadisApi.Models.DTOs;
using System.Security.Claims;

namespace NovadisApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class UsersController : ControllerBase
    {
        private readonly NovadisDbContext _context;

        public UsersController(NovadisDbContext context)
        {
            _context = context;
        }

        [HttpGet("technicians")]
        public async Task<ActionResult<ApiResponse<IEnumerable<UserDto>>>> GetTechnicians()
        {
            var technicians = await _context.Users
                .Where(u => (u.Role == "Technician" || u.Role == "Technicien" || u.Role == "Admin") && u.IsActive)
                .Select(u => new UserDto
                {
                    Id = u.Id,
                    Email = u.Email,
                    FirstName = u.FirstName ?? string.Empty,
                    LastName = u.LastName ?? string.Empty,
                    Role = UserRoleExtensions.Normalize(u.Role),
                    IsActive = u.IsActive,
                    LastLoginAt = u.LastLoginAt
                })
                .ToListAsync();

            return Ok(ApiResponse<IEnumerable<UserDto>>.SuccessResponse(technicians));
        }

        [HttpGet("me")]
        public async Task<ActionResult<ApiResponse<UserDto>>> GetMe()
        {
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                ?? User.FindFirst("userId")?.Value;

            if (!Guid.TryParse(userIdStr, out var userId))
                return Unauthorized(ApiResponse<UserDto>.ErrorResponse("Utilisateur non authentifié"));

            var user = await _context.Users.FindAsync(userId);
            if (user == null)
                return NotFound(ApiResponse<UserDto>.ErrorResponse("Utilisateur introuvable"));

            return Ok(ApiResponse<UserDto>.SuccessResponse(new UserDto
            {
                Id = user.Id,
                Email = user.Email,
                FirstName = user.FirstName ?? string.Empty,
                LastName = user.LastName ?? string.Empty,
                Role = UserRoleExtensions.Normalize(user.Role),
                IsActive = user.IsActive,
                LastLoginAt = user.LastLoginAt,
                SavedSignature = user.SavedSignature
            }));
        }

        [HttpPut("me/signature")]
        public async Task<ActionResult<ApiResponse<object>>> UpdateMySignature([FromBody] UpdateMySignatureDto body)
        {
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                ?? User.FindFirst("userId")?.Value;

            if (!Guid.TryParse(userIdStr, out var userId))
                return Unauthorized(ApiResponse<object>.ErrorResponse("Utilisateur non authentifié"));

            var user = await _context.Users.FindAsync(userId);
            if (user == null)
                return NotFound(ApiResponse<object>.ErrorResponse("Utilisateur introuvable"));

            user.SavedSignature = body.SignatureBase64;
            await _context.SaveChangesAsync();

            return Ok(ApiResponse<object>.SuccessResponse(null!, "Signature sauvegardée"));
        }
    }
}
