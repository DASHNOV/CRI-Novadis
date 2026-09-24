using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace NovadisApi.Models
{
    [Table("UserTokens")]
    public class UserToken
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        public Guid UserId { get; set; }

        [ForeignKey("UserId")]
        public User? User { get; set; }

        /// <summary>
        /// SHA-256 du refresh token (<see cref="Services.Auth.TokenHasher"/>). Le jeton
        /// lui-même n'est jamais stocké : une fuite de la base ne donne pas de session.
        /// </summary>
        [Required]
        [MaxLength(64)]
        public string RefreshTokenHash { get; set; } = string.Empty;

        public string TokenType { get; set; } = "Refresh"; // Refresh, Access, etc.

        [MaxLength(255)]
        public string? DeviceInfo { get; set; }

        [MaxLength(45)]
        public string? IpAddress { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime ExpiresAt { get; set; }

        public bool IsRevoked { get; set; } = false;

        public string? RevokedReason { get; set; }

        /// <summary>SHA-256 du jeton d'appareil de confiance, même principe.</summary>
        [MaxLength(64)]
        public string? TrustedDeviceTokenHash { get; set; }
    }
}
