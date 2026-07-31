using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using NovadisApi.Data;
using NovadisApi.Models.DTOs;
using System.Text.Json.Nodes;

namespace NovadisApi.Services
{
    public class SiteSummaryService : ISiteSummaryService
    {
        private readonly NovadisDbContext _context;
        private readonly IMemoryCache _cache;

        private static readonly HashSet<string> StopWords = new(StringComparer.OrdinalIgnoreCase)
            { "le", "la", "les", "un", "une", "de", "du", "des", "et", "ou", "en", "par", "au", "aux", "sur", "sous", "à", "ce", "qui", "que" };

        public SiteSummaryService(NovadisDbContext context, IMemoryCache cache)
        {
            _context = context;
            _cache = cache;
        }

        public void InvalidateSiteSummary(string? siteName)
        {
            if (!string.IsNullOrWhiteSpace(siteName))
                _cache.Remove($"site_summary_{siteName.ToLowerInvariant()}");
        }

        public async Task<SiteSummaryDto> GetSummaryAsync(string siteName)
        {
            var cacheKey = $"site_summary_{siteName.ToLowerInvariant()}";
            if (_cache.TryGetValue(cacheKey, out SiteSummaryDto? cached))
                return cached!;

            var summary = new SiteSummaryDto { SiteName = siteName };
            var sixMonthsAgo = DateTime.Now.AddMonths(-6);

            // Requête 1 : compte exact sur 6 mois sans limite Take
            summary.RecurrenceLast6Months = await _context.CRIForms
                .CountAsync(c => c.ClientSite == siteName && c.InterventionDate >= sixMonthsAgo);

            // Requête 2 : 50 derniers CRI pour les calculs qualitatifs
            var cris = await _context.CRIForms
                .Where(c => c.ClientSite == siteName)
                .OrderByDescending(c => c.InterventionDate)
                .Take(50)
                .ToListAsync();

            if (!cris.Any())
            {
                _cache.Set(cacheKey, summary, TimeSpan.FromMinutes(15));
                return summary;
            }

            var processedCris = new List<ProcessedCri>();

            foreach (var cri in cris)
            {
                if (string.IsNullOrEmpty(cri.Data)) continue;

                try
                {
                    var json = JsonNode.Parse(cri.Data);
                    if (json == null) continue;

                    processedCris.Add(new ProcessedCri
                    {
                        Date = cri.InterventionDate,
                        TechnicianName = GetJsonString(json, "technicianName") ?? "Inconnu",
                        IdentifiedCause = GetJsonString(json, "identifiedCause"),
                        ReplacedParts = GetJsonString(json, "replacedParts"),
                        Recommendations = GetJsonString(json, "recommendations"),
                        CybersecurityRecommendations = GetJsonString(json, "cybersecurityRecommendations"),
                        ResolutionStatus = GetJsonString(json, "resolutionStatus") ?? "nonResolu"
                    });
                }
                catch
                {
                    // Ignore malformed JSON
                }
            }

            if (!processedCris.Any())
            {
                _cache.Set(cacheKey, summary, TimeSpan.FromMinutes(15));
                return summary;
            }

            // A. Flash Info
            var lastCri = processedCris.First();
            summary.LastVisitStatus = MapResolutionStatus(lastCri.ResolutionStatus);

            // B. Timeline Critique (3 derniers événements)
            summary.Timeline = processedCris.Take(3).Select(c => new SiteTimelineEventDto
            {
                Date = c.Date,
                IdentifiedCause = c.IdentifiedCause ?? "Non spécifié",
                ReplacedParts = c.ReplacedParts ?? "-",
                TechnicianName = c.TechnicianName,
                Status = MapResolutionStatus(c.ResolutionStatus)
            }).ToList();

            // C. Héritage Technique (dédupliqué)
            var recommendations = processedCris
                .Where(c => !string.IsNullOrWhiteSpace(c.Recommendations))
                .Select(c => c.Recommendations!.Trim())
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .Take(2)
                .ToList();

            var cyberRecs = processedCris
                .Where(c => !string.IsNullOrWhiteSpace(c.CybersecurityRecommendations))
                .Select(c => "Cyber: " + c.CybersecurityRecommendations!.Trim())
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .Take(1)
                .ToList();

            summary.Recommendations.AddRange(recommendations);
            summary.Recommendations.AddRange(cyberRecs);

            // D. Analyse de Chronicité (normalisation + seuil adaptatif)
            var threeMonthsAgo = DateTime.Now.AddMonths(-3);
            var recentWithCause = processedCris
                .Where(c => c.Date >= threeMonthsAgo && !string.IsNullOrWhiteSpace(c.IdentifiedCause))
                .ToList();

            var threshold = Math.Max(2, (int)(recentWithCause.Count * 0.3));

            var chronicCause = recentWithCause
                .GroupBy(c => NormalizeCause(c.IdentifiedCause!))
                .Where(g => g.Count() >= threshold)
                .OrderByDescending(g => g.Count())
                .Select(g => g.First().IdentifiedCause)
                .FirstOrDefault();

            if (chronicCause != null)
            {
                summary.ChronicityAlert = true;
                summary.ChronicProblemDescription = chronicCause;
            }

            // E. Technicien le plus fréquent sur le site
            summary.MostFrequentTechnician = processedCris
                .GroupBy(c => c.TechnicianName)
                .OrderByDescending(g => g.Count())
                .Select(g => g.Key)
                .FirstOrDefault();

            // F. Tendance de résolution (3 derniers mois vs 3 mois précédents)
            static double RatioResolu(IEnumerable<ProcessedCri> items)
            {
                var list = items.ToList();
                return list.Count == 0 ? -1 : (double)list.Count(c => c.ResolutionStatus == "resolu") / list.Count;
            }

            var ratioRecent = RatioResolu(processedCris.Where(c => c.Date >= threeMonthsAgo));
            var ratioOld = RatioResolu(processedCris.Where(c => c.Date >= sixMonthsAgo && c.Date < threeMonthsAgo));

            summary.ResolutionTrend = (ratioRecent, ratioOld) switch
            {
                (-1, _) or (_, -1) => "Inconnu",
                var (r, o) when r > o + 0.15 => "Amélioration",
                var (r, o) when r < o - 0.15 => "Dégradation",
                _ => "Stable"
            };

            // G. Durée moyenne (colonne structurée EF, pas le JSON)
            var durations = cris.Where(c => c.DureeMinutes > 0).Select(c => (double)c.DureeMinutes).ToList();
            if (durations.Count > 0)
                summary.AverageDurationMinutes = durations.Average();

            _cache.Set(cacheKey, summary, TimeSpan.FromMinutes(15));
            return summary;
        }

        private string? GetJsonString(JsonNode json, string propertyName)
        {
            return json[propertyName]?.GetValue<string>();
        }

        private string MapResolutionStatus(string status)
        {
            return status switch
            {
                "resolu" => "Résolu",
                "partiellementResolu" => "Partiel",
                "nonResolu" => "Non Résolu",
                "enAttentePieces" => "Non Résolu (Pièces)",
                "escaladeNiveau2" => "Non Résolu (Escalade)",
                _ => "Inconnu"
            };
        }

        private string NormalizeCause(string cause) =>
            string.Join(" ", cause.ToLowerInvariant()
                .Split(' ', StringSplitOptions.RemoveEmptyEntries)
                .Where(w => !StopWords.Contains(w))
                .OrderBy(w => w));

        private class ProcessedCri
        {
            public DateTime Date { get; set; }
            public string TechnicianName { get; set; } = string.Empty;
            public string? IdentifiedCause { get; set; }
            public string? ReplacedParts { get; set; }
            public string? Recommendations { get; set; }
            public string? CybersecurityRecommendations { get; set; }
            public string ResolutionStatus { get; set; } = string.Empty;
        }
    }
}
