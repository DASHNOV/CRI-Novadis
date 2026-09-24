using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace NovadisApi.Models
{
    [Table("Users")]
    public class User
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        [EmailAddress]
        [MaxLength(255)]
        public string Email { get; set; } = string.Empty;

        [Required]
        public string PasswordHash { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string Role { get; set; } = RoleNames.Technician; // cf. RoleNames

        [MaxLength(100)]
        public string? FirstName { get; set; }

        [MaxLength(100)]
        public string? LastName { get; set; }

        [MaxLength(20)]
        public string? PhoneNumber { get; set; }

        public bool IsActive { get; set; } = true;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? LastLoginAt { get; set; }

        public string? SavedSignature { get; set; }

        /// <summary>
        /// Un compte ne peut se connecter que s'il est actif et que son rôle est
        /// reconnu — un rôle inconnu n'est jamais traité comme technicien.
        /// </summary>
        public bool CanSignIn() => IsActive && UserRoleExtensions.FromString(Role) != null;

        // Relations
        public virtual ICollection<CRIForm> CRIForms { get; set; } = new List<CRIForm>();
        public virtual ICollection<AuditLog> AuditLogs { get; set; } = new List<AuditLog>();
    }
}
