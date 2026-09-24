using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace NovadisApi.Models
{
    [Table("AuthAttempts")]
    public class AuthAttempt
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        [EmailAddress]
        [MaxLength(255)]
        public string Email { get; set; } = string.Empty;

        /// <summary>HMAC-SHA256 du code, clé <see cref="CodeSalt"/> (base64).</summary>
        [Required]
        public string CodeHash { get; set; } = string.Empty;

        /// <summary>Sel aléatoire propre à la tentative (16 octets, base64).</summary>
        [Required]
        [MaxLength(32)]
        public string CodeSalt { get; set; } = string.Empty;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime ExpiresAt { get; set; }

        [MaxLength(45)]
        public string? IpAddress { get; set; }

        public bool IsUsed { get; set; } = false;

        public int FailedAttempts { get; set; } = 0;
    }
}
