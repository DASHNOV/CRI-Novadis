using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace NovadisApi.Models
{
    [Table("CRIForms")]
    public class CRIForm
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        public Guid TechnicianId { get; set; }

        [Required]
        [MaxLength(50)]
        public string InterventionType { get; set; } = string.Empty; // Project, Service

        [Required]
        [MaxLength(50)]
        public string Category { get; set; } = string.Empty; // Installation, Maintenance, etc.

        [Required]
        public DateTime InterventionDate { get; set; }

        [Required]
        [MaxLength(255)]
        public string ClientName { get; set; } = string.Empty;

        [MaxLength(255)]
        public string? ClientAddress { get; set; }

        [MaxLength(255)]
        public string? ClientSite { get; set; }

        [MaxLength(20)]
        public string? ClientPhone { get; set; }

        // Regex alignée sur la validation frontend (form_validators.dart) :
        // pas de points consécutifs/en bordure, TLD >= 2 lettres.
        // RegularExpression laisse passer null et chaîne vide (email optionnel).
        [RegularExpression(
            @"^[a-zA-Z0-9!#$%&*+/=?^_`{|}~-]+(?:\.[a-zA-Z0-9!#$%&*+/=?^_`{|}~-]+)*@[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$",
            ErrorMessage = "Format d'email invalide")]
        [MaxLength(255)]
        public string? ClientEmail { get; set; }

        public string? WorkDescription { get; set; }

        public string? MaterialsUsed { get; set; }

        public decimal? Duration { get; set; } // En heures

        [MaxLength(50)]
        public string Status { get; set; } = "Draft"; // Draft, Submitted, Validated

        // Champ JSON pour données spécifiques (conservé pour rétrocompatibilité)
        public string? Data { get; set; }

        public string? TechnicianSignature { get; set; } // Base64

        public string? ClientSignature { get; set; } // Base64

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }

        public DateTime? SubmittedAt { get; set; }

        // ── Colonnes extraites du JSON Data (Phase 1 — statistiques) ──

        // Horaires
        public TimeSpan? HeureDebut { get; set; }
        public TimeSpan? HeureFin { get; set; }
        public int? DureeMinutes { get; set; }

        // Localisation client (extraits du JSON)
        [MaxLength(100)]
        public string? Ville { get; set; }

        [MaxLength(10)]
        public string? CodePostal { get; set; }

        [MaxLength(100)]
        public string? Pays { get; set; }

        [MaxLength(100)]
        public string? ClientContact { get; set; }

        // Champs Service
        [MaxLength(50)]
        public string? TicketNumber { get; set; }

        [MaxLength(30)]
        public string? ResolutionStatus { get; set; } // resolu, nonResolu, partiellementResolu, enAttente

        public bool? AdditionalInterventionRequired { get; set; }

        // Champs Projet
        [MaxLength(255)]
        public string? ProjectName { get; set; }

        [MaxLength(50)]
        public string? ProjectNumber { get; set; }

        [MaxLength(30)]
        public string? ProjectPhase { get; set; } // etude, realisation, maintenance

        [MaxLength(30)]
        public string? ProjectStatus { get; set; } // enCours, termine, suspendu

        // ── Relations normalisées (Phase 2) ──

        public int? SiteID { get; set; }

        [ForeignKey("SiteID")]
        public virtual Site? Site { get; set; }

        public Guid? ClientID { get; set; }

        [ForeignKey("ClientID")]
        public virtual Client? Client { get; set; }

        // Relations existantes
        [ForeignKey("TechnicianId")]
        public virtual User? Technician { get; set; }

        public virtual ICollection<CRIPhoto> Photos { get; set; } = new List<CRIPhoto>();
    }
}
