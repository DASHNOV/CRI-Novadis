using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using NovadisApi.Data;
using NovadisApi.Models;
using NovadisApi.Services.Export;
using NovadisApi.Services.Storage;
using System.Security.Claims;
using System.Text.Json;

namespace NovadisApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class ExportController : ControllerBase
    {
        private const string XlsxMime = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";

        private readonly IXlsxExportService _xlsx;
        private readonly IObjectStorageService _storage;
        private readonly NovadisDbContext _db;
        private readonly ILogger<ExportController> _logger;

        public ExportController(
            IXlsxExportService xlsx,
            IObjectStorageService storage,
            NovadisDbContext db,
            ILogger<ExportController> logger)
        {
            _xlsx = xlsx;
            _storage = storage;
            _db = db;
            _logger = logger;
        }

        private Guid? GetCurrentUserId()
        {
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                ?? User.FindFirst("userId")?.Value;
            return Guid.TryParse(userIdStr, out var userId) ? userId : null;
        }

        /// <summary>
        /// Génère un XLSX pour un CRI précis, le persiste dans le stockage et l'historise.
        /// </summary>
        [HttpGet("cri/{id:guid}.xlsx")]
        public async Task<IActionResult> ExportCri(Guid id, CancellationToken ct)
        {
            var userId = GetCurrentUserId();
            if (userId == null) return Unauthorized();

            try
            {
                var result = await _xlsx.GenerateSingleCriAsync(id, userId.Value, User.IsInRole("Admin"));
                if (result == null)
                {
                    _logger.LogWarning("XLSX export: CRI {Id} introuvable ou accès refusé pour {User}", id, userId);
                    return NotFound();
                }

                var objectKey = BuildObjectKey(userId.Value, result.Value.Filename);
                await _storage.UploadAsync(objectKey, result.Value.Bytes, XlsxMime, ct);

                _db.ExportedDocuments.Add(new ExportedDocument
                {
                    UserId = userId.Value,
                    CriId = id,
                    Filename = result.Value.Filename,
                    FileType = "xlsx",
                    ExportType = "cri",
                    StoragePath = objectKey,
                    SizeBytes = result.Value.Bytes.LongLength,
                    CreatedAt = DateTime.UtcNow,
                });
                await _db.SaveChangesAsync(ct);

                return File(result.Value.Bytes, XlsxMime, result.Value.Filename);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "XLSX export CRI {Id} — échec de génération", id);
                return StatusCode(500, new { error = "La génération de l'export a échoué." });
            }
        }

        /// <summary>
        /// Génère un XLSX agrégé pour une période (jour/semaine/mois/année).
        /// </summary>
        /// <param name="range">day, week, month ou year</param>
        /// <param name="date">Date de référence (ISO 8601). Par défaut: aujourd'hui UTC.</param>
        /// <param name="detail">full (défaut) ou summary — niveau de détail du rapport.</param>
        [HttpGet("period.xlsx")]
        public async Task<IActionResult> ExportByPeriod([FromQuery] string range, [FromQuery] DateTime? date, [FromQuery] string? detail, CancellationToken ct)
        {
            var userId = GetCurrentUserId();
            if (userId == null) return Unauthorized();

            if (!TryParsePeriod(range, out var period))
            {
                return BadRequest(new { error = "Paramètre 'range' invalide. Valeurs: day, week, month, year." });
            }

            if (!TryParseDetailLevel(detail, out var detailLevel))
            {
                return BadRequest(new { error = "Paramètre 'detail' invalide. Valeurs: full, summary." });
            }

            var reference = (date ?? DateTime.UtcNow).Date;
            try
            {
                var result = await _xlsx.GeneratePeriodAsync(period, reference, userId.Value, User.IsInRole("Admin"), detailLevel);

                var objectKey = BuildObjectKey(userId.Value, result.Filename);
                await _storage.UploadAsync(objectKey, result.Bytes, XlsxMime, ct);

                var (periodStart, periodEnd) = ComputePeriodRange(period, reference);
                var metadata = JsonSerializer.Serialize(new
                {
                    range = period.ToString().ToLowerInvariant(),
                    scope = User.IsInRole("Admin") ? "global" : "personnel",
                    referenceDate = reference,
                    detailLevel = detailLevel.ToString().ToLowerInvariant(),
                });

                _db.ExportedDocuments.Add(new ExportedDocument
                {
                    UserId = userId.Value,
                    CriId = null,
                    Filename = result.Filename,
                    FileType = "xlsx",
                    ExportType = "period-" + period.ToString().ToLowerInvariant(),
                    StoragePath = objectKey,
                    SizeBytes = result.Bytes.LongLength,
                    CreatedAt = DateTime.UtcNow,
                    PeriodStart = periodStart,
                    PeriodEnd = periodEnd,
                    Metadata = metadata,
                });
                await _db.SaveChangesAsync(ct);

                return File(result.Bytes, XlsxMime, result.Filename);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "XLSX export période {Range} {Date} — échec", range, reference);
                return StatusCode(500, new { error = "La génération de l'export a échoué." });
            }
        }

        private static string BuildObjectKey(Guid userId, string filename)
        {
            var today = DateTime.UtcNow;
            return $"{userId}/{today:yyyy}/{today:MM}/{Guid.NewGuid():N}-{filename}";
        }

        private static bool TryParsePeriod(string? raw, out ExportPeriod period)
        {
            switch ((raw ?? string.Empty).Trim().ToLowerInvariant())
            {
                case "day": case "jour": period = ExportPeriod.Day; return true;
                case "week": case "semaine": period = ExportPeriod.Week; return true;
                case "month": case "mois": period = ExportPeriod.Month; return true;
                case "year": case "annee": case "année": period = ExportPeriod.Year; return true;
                default: period = default; return false;
            }
        }

        private static bool TryParseDetailLevel(string? raw, out ExportDetailLevel detailLevel)
        {
            switch ((raw ?? "full").Trim().ToLowerInvariant())
            {
                case "": case "full": case "complet": detailLevel = ExportDetailLevel.Full; return true;
                case "summary": case "resume": case "résumé": detailLevel = ExportDetailLevel.Summary; return true;
                default: detailLevel = default; return false;
            }
        }

        private static (DateTime Start, DateTime End) ComputePeriodRange(ExportPeriod period, DateTime referenceDate)
        {
            var d = referenceDate.Date;
            return period switch
            {
                ExportPeriod.Day => (d, d.AddDays(1)),
                ExportPeriod.Week => BuildWeekRange(d),
                ExportPeriod.Month => (new DateTime(d.Year, d.Month, 1), new DateTime(d.Year, d.Month, 1).AddMonths(1)),
                ExportPeriod.Year => (new DateTime(d.Year, 1, 1), new DateTime(d.Year + 1, 1, 1)),
                _ => (d, d.AddDays(1))
            };
        }

        private static (DateTime Start, DateTime End) BuildWeekRange(DateTime date)
        {
            var diff = ((int)date.DayOfWeek + 6) % 7;
            var monday = date.AddDays(-diff);
            return (monday, monday.AddDays(7));
        }
    }
}
