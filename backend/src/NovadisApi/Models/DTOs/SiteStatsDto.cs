namespace NovadisApi.Models.DTOs
{
    /// <summary>
    /// Statistiques agrégées par site
    /// </summary>
    public class SiteStatsDto
    {
        public int? SiteID { get; set; }
        public string SiteNom { get; set; } = string.Empty;
        public string? ClientNom { get; set; }
        public string? Ville { get; set; }
        public int TotalInterventions { get; set; }
        public double? DureeMoyenneMinutes { get; set; }
        public int TotalServices { get; set; }
        public int TotalProjets { get; set; }
        public int TotalResolu { get; set; }
        public int TotalNonResolu { get; set; }
        public int TotalRecurrenceRequise { get; set; }
        public double TauxRecurrence { get; set; }
        public string? TopCategorie { get; set; }
        public int TopCategorieCount { get; set; }
        public DateTime? DerniereIntervention { get; set; }
        public int TechniciensDistincts { get; set; }
        public Dictionary<string, int>? RepartitionParCategorie { get; set; }
    }
}
