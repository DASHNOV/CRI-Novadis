namespace NovadisApi.Models.DTOs
{
    /// <summary>
    /// Statistiques détaillées par technicien
    /// </summary>
    public class TechnicianDetailedStatsDto
    {
        public Guid Id { get; set; }
        public string Prenom { get; set; } = string.Empty;
        public string Nom { get; set; } = string.Empty;
        public string NomComplet => $"{Prenom} {Nom}";
        public int TotalInterventions { get; set; }
        public int SitesDistincts { get; set; }
        public int ClientsDistincts { get; set; }
        public double? DureeMoyenneMinutes { get; set; }
        public double TotalHeures { get; set; }
        public int TotalServices { get; set; }
        public int TotalProjets { get; set; }
        public int TotalResolu { get; set; }
        public int TotalNonResolu { get; set; }
        public int TotalRecurrenceRequise { get; set; }
        public DateTime? DerniereIntervention { get; set; }
        public List<string>? TopSites { get; set; }
        public Dictionary<string, int>? RepartitionParType { get; set; }
    }

    /// <summary>
    /// Statistiques de distribution croisées
    /// </summary>
    public class DistributionStatsDto
    {
        public List<CrossTabEntry>? CategorieParSite { get; set; }
        public List<CrossTabEntry>? TechnicienParSite { get; set; }
        public List<EvolutionMensuelleEntry>? EvolutionMensuelle { get; set; }
        public Dictionary<string, int>? RepartitionParVille { get; set; }
        public Dictionary<string, int>? RepartitionParCategorie { get; set; }
    }

    public class CrossTabEntry
    {
        public string Ligne { get; set; } = string.Empty;
        public string Colonne { get; set; } = string.Empty;
        public int Valeur { get; set; }
    }

    public class EvolutionMensuelleEntry
    {
        public int Annee { get; set; }
        public int Mois { get; set; }
        public string Label { get; set; } = string.Empty;
        public int TotalInterventions { get; set; }
        public int Services { get; set; }
        public int Projets { get; set; }
        public int Resolu { get; set; }
        public double? DureeMoyenneMinutes { get; set; }
    }
}
