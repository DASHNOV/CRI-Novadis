namespace NovadisApi.Models.DTOs
{
    /// <summary>
    /// Statistiques globales (admin uniquement)
    /// </summary>
    public class GlobalStatsDto
    {
        public int TotalCeMois { get; set; }
        public int TotalSignes { get; set; }
        public int TotalEnAttente { get; set; }
        public int TechniciensActifs { get; set; }

        // Stats enrichies Phase 1
        public double? DureeMoyenneMinutes { get; set; }
        public int TotalProjets { get; set; }
        public int TotalServices { get; set; }
        public int TotalResolu { get; set; }
        public int TotalNonResolu { get; set; }
        public int TotalRecurrenceRequise { get; set; }
        public Dictionary<string, int>? RepartitionParVille { get; set; }
    }
}
