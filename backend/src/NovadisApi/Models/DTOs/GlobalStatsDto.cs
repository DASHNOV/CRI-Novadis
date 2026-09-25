namespace NovadisApi.Models.DTOs
{
    /// <summary>
    /// Statistiques globales (admin uniquement)
    /// </summary>
    public class GlobalStatsDto
    {
        /// <summary>Nombre de CRI sur la période demandée (toute la base sans période).</summary>
        public int TotalInterventions { get; set; }

        /// <summary>
        /// Ancien nom de <see cref="TotalInterventions"/>, trompeur : la valeur suit la
        /// période demandée, pas le mois en cours. Conservé pour les APK déjà installés.
        /// </summary>
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

        /// <summary>
        /// Chiffres clés de la période précédente de même durée (tendances), <c>null</c>
        /// sans période (toute la base : pas de « précédent »).
        /// </summary>
        public PeriodComparisonDto? PeriodePrecedente { get; set; }
    }

    public class PeriodComparisonDto
    {
        public int TotalInterventions { get; set; }
        public int TotalResolu { get; set; }
        public double? DureeMoyenneMinutes { get; set; }
        public int TotalRecurrenceRequise { get; set; }
    }
}
