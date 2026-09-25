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

        /// <summary>Coordonnées du site normalisé (<c>null</c> : saisie libre, non géocodé ou à vérifier).</summary>
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }

        /// <summary><c>housenumber</c>, <c>street</c>, <c>locality</c>, <c>municipality</c> (centre de la commune).</summary>
        public string? GeocodagePrecision { get; set; }

        /// <summary>
        /// Origine des coordonnées : <c>referentiel</c> (site normalisé) ou <c>cri</c>
        /// (adresse saisie dans le CRI, site hors référentiel) ; <c>null</c> sans coordonnées.
        /// </summary>
        public string? LocalisationSource { get; set; }
    }
}
