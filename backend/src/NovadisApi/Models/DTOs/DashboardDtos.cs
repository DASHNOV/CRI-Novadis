using NovadisApi.Services.Stats;

namespace NovadisApi.Models.DTOs
{
    /// <summary>
    /// Paramètres communs des endpoints de statistiques (query string).
    /// <c>from</c> / <c>to</c> priment sur <c>period</c>.
    /// </summary>
    public class StatsQuery
    {
        /// <summary>Les N derniers jours, aujourd'hui compris (nom historique, APK installés).</summary>
        public int? Period { get; set; }

        /// <summary>Première journée incluse.</summary>
        public DateOnly? From { get; set; }

        /// <summary>Dernière journée <b>incluse</b>.</summary>
        public DateOnly? To { get; set; }

        /// <summary>Restreint aux CRI de ce technicien (ignoré sur <c>/api/personal</c>).</summary>
        public Guid? TechnicienId { get; set; }

        /// <summary>Restreint à ce site (nom).</summary>
        public string? Site { get; set; }

        public const int MaxPeriodDays = 3660;

        /// <summary>Convertit en <see cref="StatsFilter"/> ; <c>false</c> et un message si incohérent.</summary>
        public bool TryToFilter(out StatsFilter filter, out string? error)
        {
            filter = StatsFilter.All;
            error = null;

            if (From.HasValue || To.HasValue)
            {
                if (From.HasValue && To.HasValue && To.Value < From.Value)
                {
                    error = "La date de fin précède la date de début.";
                    return false;
                }
                filter = new StatsFilter
                {
                    From = From?.ToDateTime(TimeOnly.MinValue),
                    To = To?.AddDays(1).ToDateTime(TimeOnly.MinValue),
                };
            }
            else if (Period is > 0)
            {
                if (Period > MaxPeriodDays)
                {
                    error = $"Période trop longue (maximum {MaxPeriodDays} jours).";
                    return false;
                }
                filter = StatsFilter.LastDays(Period.Value);
            }

            filter = filter with
            {
                TechnicianId = TechnicienId,
                Site = string.IsNullOrWhiteSpace(Site) ? null : Site.Trim(),
            };
            return true;
        }
    }

    /// <summary>Courbe d'évolution du nombre d'interventions.</summary>
    public class EvolutionDto
    {
        /// <summary><c>day</c>, <c>week</c> (lundi) ou <c>month</c>, selon la durée couverte.</summary>
        public string Granularity { get; set; } = "day";
        public List<EvolutionPointDto> Points { get; set; } = new();
    }

    public class EvolutionPointDto
    {
        /// <summary>Début du pas (minuit ; lundi pour une semaine ; 1er pour un mois).</summary>
        public DateTime Debut { get; set; }
        public string Label { get; set; } = string.Empty;
        public int Total { get; set; }
        public int Services { get; set; }
        public int Projets { get; set; }
        public int Resolu { get; set; }
    }

    /// <summary>Intervention récente (liste du dashboard), sans le JSON <c>Data</c>.</summary>
    public class RecentInterventionDto
    {
        public Guid Id { get; set; }
        public string InterventionType { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        public DateTime InterventionDate { get; set; }
        public Guid TechnicianId { get; set; }
        public string TechnicienNom { get; set; } = string.Empty;
        public string? SiteNom { get; set; }
        public string ClientNom { get; set; } = string.Empty;
        public string? ResolutionStatus { get; set; }
        public string? ProjectStatus { get; set; }
        public int? DureeMinutes { get; set; }
    }
}
