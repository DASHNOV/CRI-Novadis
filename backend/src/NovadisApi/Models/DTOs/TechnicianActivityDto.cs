namespace NovadisApi.Models.DTOs
{
    /// <summary>
    /// Activité d'un technicien (pour le dashboard admin)
    /// </summary>
    public class TechnicianActivityDto
    {
        public Guid Id { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string FullName => $"{FirstName} {LastName}";
        public int NbCriTotal { get; set; }
        public int NbCri7j { get; set; }
        public int NbCri30j { get; set; }
    }

    /// <summary>
    /// Activité journalière pour graphique (admin)
    /// </summary>
    public class DailyActivityDto
    {
        public DateTime Jour { get; set; }
        public int Nb { get; set; }
    }

    /// <summary>
    /// CRI avec informations du technicien (admin)
    /// </summary>
    public class CRIWithTechnicianDto
    {
        public Guid Id { get; set; }
        public Guid TechnicianId { get; set; }
        public string InterventionType { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        public DateTime InterventionDate { get; set; }
        public string ClientName { get; set; } = string.Empty;
        public string? ClientAddress { get; set; }
        public string? ClientSite { get; set; }
        public string? ClientPhone { get; set; }
        public string? ClientEmail { get; set; }
        public string? WorkDescription { get; set; }
        public string? MaterialsUsed { get; set; }
        public decimal? Duration { get; set; }
        public string Status { get; set; } = "Draft";
        public string? Data { get; set; }
        public string? TechnicianSignature { get; set; }
        public string? ClientSignature { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public DateTime? SubmittedAt { get; set; }

        // Colonnes extraites du JSON
        public TimeSpan? HeureDebut { get; set; }
        public TimeSpan? HeureFin { get; set; }
        public int? DureeMinutes { get; set; }
        public string? Ville { get; set; }
        public string? CodePostal { get; set; }
        public string? Pays { get; set; }
        public string? ClientContact { get; set; }
        public string? TicketNumber { get; set; }
        public string? ResolutionStatus { get; set; }
        public bool? AdditionalInterventionRequired { get; set; }
        public string? ProjectName { get; set; }
        public string? ProjectNumber { get; set; }
        public string? ProjectPhase { get; set; }
        public string? ProjectStatus { get; set; }

        // Relations normalisées (Phase 2)
        public int? SiteID { get; set; }
        public string? SiteNom { get; set; }
        public Guid? ClientID { get; set; }
        public string? ClientRaisonSociale { get; set; }

        // Info du technicien
        public string TechnicianFirstName { get; set; } = string.Empty;
        public string TechnicianLastName { get; set; } = string.Empty;
        public string TechnicianEmail { get; set; } = string.Empty;
        public string TechnicianFullName => $"{TechnicianFirstName} {TechnicianLastName}";
    }
}
