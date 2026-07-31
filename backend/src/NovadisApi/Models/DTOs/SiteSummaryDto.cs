namespace NovadisApi.Models.DTOs
{
    public class SiteSummaryDto
    {
        public string SiteName { get; set; } = string.Empty;
        
        // A. Flash Info
        public string LastVisitStatus { get; set; } = "Inconnu"; // Résolu, Partiel, Non Résolu
        public int RecurrenceLast6Months { get; set; }

        // B. Timeline Critique (Last 3 events)
        public List<SiteTimelineEventDto> Timeline { get; set; } = new List<SiteTimelineEventDto>();

        // C. Héritage Technique
        public List<string> Recommendations { get; set; } = new List<string>();

        // D. Analyse de Chronicité
        public bool ChronicityAlert { get; set; }
        public string? ChronicProblemDescription { get; set; }

        // E. Indicateurs supplémentaires
        public string? MostFrequentTechnician { get; set; }
        public string ResolutionTrend { get; set; } = "Inconnu"; // Amélioration, Stable, Dégradation, Inconnu
        public double? AverageDurationMinutes { get; set; }
    }

    public class SiteTimelineEventDto
    {
        public DateTime Date { get; set; }
        public string IdentifiedCause { get; set; } = string.Empty;
        public string ReplacedParts { get; set; } = string.Empty;
        public string TechnicianName { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
    }
}
