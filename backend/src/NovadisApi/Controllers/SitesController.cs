using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NovadisApi.Data;
using NovadisApi.Models;
using NovadisApi.Models.DTOs;
using System.Globalization;
using System.Text;

namespace NovadisApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class SitesController : ControllerBase
    {
        private readonly NovadisDbContext _context;
        private readonly ILogger<SitesController> _logger;

        public SitesController(NovadisDbContext context, ILogger<SitesController> logger)
        {
            _context = context;
            _logger = logger;
        }

        /// <summary>
        /// Recherche de sites avec filtrage insensible à la casse et aux accents.
        /// Recherche par nom du site, adresse, ville ou code postal.
        /// </summary>
        [HttpGet("search")]
        [AllowAnonymous]
        public async Task<ActionResult<ApiResponse<IEnumerable<SiteDto>>>> SearchSites([FromQuery] string q)
        {
            if (string.IsNullOrWhiteSpace(q) || q.Length < 2)
            {
                return Ok(ApiResponse<IEnumerable<SiteDto>>.SuccessResponse(new List<SiteDto>()));
            }

            var pattern = $"%{RemoveDiacritics(q)}%";

            var sites = await _context.Sites
                .Where(s =>
                    EF.Functions.ILike(NovadisDbContext.Unaccent(s.NomDuSite), pattern) ||
                    (s.Adresse != null && EF.Functions.ILike(NovadisDbContext.Unaccent(s.Adresse), pattern)) ||
                    (s.Ville != null && EF.Functions.ILike(NovadisDbContext.Unaccent(s.Ville), pattern)) ||
                    (s.CodePostal != null && s.CodePostal.Contains(q))
                )
                .OrderBy(s => s.NomDuSite)
                .Take(30)
                .Select(s => new SiteDto
                {
                    Numero = s.Numero,
                    NomDuSite = s.NomDuSite,
                    Adresse = s.Adresse,
                    Ville = s.Ville,
                    CodePostal = s.CodePostal,
                    Pays = s.Pays
                })
                .ToListAsync();

            return Ok(ApiResponse<IEnumerable<SiteDto>>.SuccessResponse(sites));
        }

        /// <summary>
        /// Récupère tous les sites (paginé).
        /// </summary>
        [HttpGet]
        public async Task<ActionResult<ApiResponse<IEnumerable<SiteDto>>>> GetAllSites(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 50)
        {
            var sites = await _context.Sites
                .OrderBy(s => s.NomDuSite)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(s => new SiteDto
                {
                    Numero = s.Numero,
                    NomDuSite = s.NomDuSite,
                    Adresse = s.Adresse,
                    Ville = s.Ville,
                    CodePostal = s.CodePostal,
                    Pays = s.Pays
                })
                .ToListAsync();

            return Ok(ApiResponse<IEnumerable<SiteDto>>.SuccessResponse(sites));
        }

        /// <summary>
        /// Import des sites depuis le CSV (admin uniquement).
        /// </summary>
        [HttpPost("import")]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult<ApiResponse<object>>> ImportSites()
        {
            try
            {
                var csvPath = Path.Combine(Directory.GetCurrentDirectory(), "..", "..", "..",
                    "Liste Sites NovaDIS - extract Gx 20260318.csv");

                // Try multiple possible locations
                if (!System.IO.File.Exists(csvPath))
                {
                    csvPath = Path.Combine(Directory.GetCurrentDirectory(),
                        "Liste Sites NovaDIS - extract Gx 20260318.csv");
                }

                if (!System.IO.File.Exists(csvPath))
                {
                    return NotFound(ApiResponse<object>.ErrorResponse("Fichier CSV introuvable"));
                }

                var count = await ImportCsvFile(csvPath);
                return Ok(ApiResponse<object>.SuccessResponse(new { imported = count },
                    $"{count} sites importés avec succès"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Erreur lors de l'import des sites");
                return StatusCode(500, ApiResponse<object>.ErrorResponse("L'import des sites a échoué."));
            }
        }

        private async Task<int> ImportCsvFile(string csvPath)
        {
            var lines = await System.IO.File.ReadAllLinesAsync(csvPath, Encoding.Latin1);
            var count = 0;

            // Skip header line
            for (int i = 1; i < lines.Length; i++)
            {
                var line = lines[i].Trim();
                if (string.IsNullOrWhiteSpace(line)) continue;

                var fields = line.Split(';');
                if (fields.Length < 8) continue;

                if (!int.TryParse(fields[0].Trim(), out var numero)) continue;

                var site = new Site
                {
                    Numero = numero,
                    NomDuSite = fields[1].Trim(),
                    Adresse = NullIfEmpty(fields[2].Trim()),
                    Ville = NullIfEmpty(fields[3].Trim()),
                    CodePostal = NullIfEmpty(fields[4].Trim()),
                    Pays = NullIfEmpty(fields[5].Trim()),
                    ResponsableDorigine = NullIfEmpty(fields[6].Trim()),
                    DateDeCreation = TryParseDate(fields[7].Trim())
                };

                var existing = await _context.Sites.FindAsync(numero);
                if (existing != null)
                {
                    existing.NomDuSite = site.NomDuSite;
                    existing.Adresse = site.Adresse;
                    existing.Ville = site.Ville;
                    existing.CodePostal = site.CodePostal;
                    existing.Pays = site.Pays;
                    existing.ResponsableDorigine = site.ResponsableDorigine;
                    existing.DateDeCreation = site.DateDeCreation;
                }
                else
                {
                    _context.Sites.Add(site);
                }
                count++;
            }

            await _context.SaveChangesAsync();
            return count;
        }

        private static string? NullIfEmpty(string value)
            => string.IsNullOrWhiteSpace(value) ? null : value;

        private static DateTime? TryParseDate(string value)
        {
            if (DateTime.TryParseExact(value, "dd/MM/yyyy", CultureInfo.InvariantCulture,
                DateTimeStyles.None, out var date))
                return date;
            return null;
        }

        private static string RemoveDiacritics(string text)
        {
            var normalizedString = text.Normalize(NormalizationForm.FormD);
            var sb = new StringBuilder(normalizedString.Length);
            foreach (var c in normalizedString)
            {
                var unicodeCategory = CharUnicodeInfo.GetUnicodeCategory(c);
                if (unicodeCategory != UnicodeCategory.NonSpacingMark)
                    sb.Append(c);
            }
            return sb.ToString().Normalize(NormalizationForm.FormC);
        }
    }

    public class SiteDto
    {
        public int Numero { get; set; }
        public string NomDuSite { get; set; } = string.Empty;
        public string? Adresse { get; set; }
        public string? Ville { get; set; }
        public string? CodePostal { get; set; }
        public string? Pays { get; set; }
    }
}
