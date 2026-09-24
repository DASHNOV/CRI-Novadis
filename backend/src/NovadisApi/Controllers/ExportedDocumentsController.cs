using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NovadisApi.Data;
using NovadisApi.Models;
using NovadisApi.Services.Storage;
using System.ComponentModel.DataAnnotations;
using System.Security.Claims;
using NovadisApi.Authorization;

namespace NovadisApi.Controllers
{
    /// <summary>
    /// Gestion de l'historique des documents exportés (PDF, XLSX).
    /// Admin : voit tous les documents. Technicien : voit uniquement les siens.
    /// </summary>
    [ApiController]
    [Route("api/exported-documents")]
    [Authorize]
    public class ExportedDocumentsController : ControllerBase
    {
        private readonly NovadisDbContext _db;
        private readonly IObjectStorageService _storage;
        private readonly ILogger<ExportedDocumentsController> _logger;

        private static readonly HashSet<string> AllowedFileTypes = new(StringComparer.OrdinalIgnoreCase)
        {
            "pdf", "xlsx"
        };

        private static readonly Dictionary<string, string> ContentTypes = new(StringComparer.OrdinalIgnoreCase)
        {
            ["pdf"] = "application/pdf",
            ["xlsx"] = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        };

        public ExportedDocumentsController(
            NovadisDbContext db,
            IObjectStorageService storage,
            ILogger<ExportedDocumentsController> logger)
        {
            _db = db;
            _storage = storage;
            _logger = logger;
        }

        private Guid? GetCurrentUserId()
        {
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                ?? User.FindFirst("userId")?.Value;
            return Guid.TryParse(userIdStr, out var userId) ? userId : null;
        }

        /// <summary>
        /// Liste les documents. Admin -> tous, Technicien -> uniquement les siens.
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> List(
            [FromQuery] string? fileType = null,
            [FromQuery] string? exportType = null,
            [FromQuery] int skip = 0,
            [FromQuery] int take = 200,
            CancellationToken ct = default)
        {
            var userId = GetCurrentUserId();
            if (userId == null) return Unauthorized();

            var canReadAll = User.HasCapability(Capabilities.DocumentsReadAll);

            IQueryable<ExportedDocument> query = _db.ExportedDocuments
                .Include(d => d.User)
                .AsNoTracking();

            if (!canReadAll)
            {
                query = query.Where(d => d.UserId == userId.Value);
            }

            if (!string.IsNullOrWhiteSpace(fileType))
            {
                var ft = fileType.ToLowerInvariant();
                query = query.Where(d => d.FileType == ft);
            }

            if (!string.IsNullOrWhiteSpace(exportType))
            {
                var et = exportType.ToLowerInvariant();
                query = query.Where(d => d.ExportType == et);
            }

            var total = await query.CountAsync(ct);

            var items = await query
                .OrderByDescending(d => d.CreatedAt)
                .Skip(Math.Max(skip, 0))
                .Take(Math.Clamp(take, 1, 1000))
                .Select(d => new ExportedDocumentDto
                {
                    Id = d.Id,
                    UserId = d.UserId,
                    UserName = d.User != null ? $"{d.User.FirstName} {d.User.LastName}".Trim() : null,
                    UserEmail = d.User != null ? d.User.Email : null,
                    CriId = d.CriId,
                    Filename = d.Filename,
                    FileType = d.FileType,
                    ExportType = d.ExportType,
                    SizeBytes = d.SizeBytes,
                    CreatedAt = d.CreatedAt,
                    SharedAt = d.SharedAt,
                    PeriodStart = d.PeriodStart,
                    PeriodEnd = d.PeriodEnd,
                    Metadata = d.Metadata,
                })
                .ToListAsync(ct);

            return Ok(new { total, items });
        }

        /// <summary>Télécharge le contenu binaire d'un document.</summary>
        [HttpGet("{id:guid}/download")]
        public async Task<IActionResult> Download(Guid id, CancellationToken ct)
        {
            var userId = GetCurrentUserId();
            if (userId == null) return Unauthorized();

            var doc = await _db.ExportedDocuments.FirstOrDefaultAsync(d => d.Id == id, ct);
            if (doc == null) return NotFound();

            if (!User.HasCapability(Capabilities.DocumentsReadAll) && doc.UserId != userId.Value)
            {
                return Forbid();
            }

            try
            {
                var (bytes, contentType) = await _storage.DownloadAsync(doc.StoragePath, ct);
                return File(bytes, contentType, doc.Filename);
            }
            catch (FileNotFoundException)
            {
                _logger.LogWarning("Fichier manquant dans le stockage pour document {Id} ({Path})", doc.Id, doc.StoragePath);
                return NotFound(new { error = "Fichier introuvable dans le stockage." });
            }
        }

        /// <summary>Renomme un document.</summary>
        [HttpPatch("{id:guid}")]
        public async Task<IActionResult> Rename(Guid id, [FromBody] RenameRequest body, CancellationToken ct)
        {
            var userId = GetCurrentUserId();
            if (userId == null) return Unauthorized();

            if (body == null || string.IsNullOrWhiteSpace(body.Filename))
            {
                return BadRequest(new { error = "Filename requis." });
            }

            var doc = await _db.ExportedDocuments.FirstOrDefaultAsync(d => d.Id == id, ct);
            if (doc == null) return NotFound();

            if (!User.HasCapability(Capabilities.DocumentsManageAny) && doc.UserId != userId.Value)
            {
                return Forbid();
            }

            doc.Filename = Truncate(body.Filename.Trim(), 300);
            await _db.SaveChangesAsync(ct);
            return NoContent();
        }

        /// <summary>Marque un document comme partagé (met à jour SharedAt).</summary>
        [HttpPost("{id:guid}/mark-shared")]
        public async Task<IActionResult> MarkShared(Guid id, CancellationToken ct)
        {
            var userId = GetCurrentUserId();
            if (userId == null) return Unauthorized();

            var doc = await _db.ExportedDocuments.FirstOrDefaultAsync(d => d.Id == id, ct);
            if (doc == null) return NotFound();

            if (!User.HasCapability(Capabilities.DocumentsManageAny) && doc.UserId != userId.Value)
            {
                return Forbid();
            }

            doc.SharedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync(ct);
            return NoContent();
        }

        /// <summary>Supprime un document et son binaire.</summary>
        [HttpDelete("{id:guid}")]
        public async Task<IActionResult> Delete(Guid id, CancellationToken ct)
        {
            var userId = GetCurrentUserId();
            if (userId == null) return Unauthorized();

            var doc = await _db.ExportedDocuments.FirstOrDefaultAsync(d => d.Id == id, ct);
            if (doc == null) return NotFound();

            if (!User.HasCapability(Capabilities.DocumentsManageAny) && doc.UserId != userId.Value)
            {
                return Forbid();
            }

            try
            {
                await _storage.DeleteAsync(doc.StoragePath, ct);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Échec suppression stockage {Path} (on supprime quand même la fiche)", doc.StoragePath);
            }

            _db.ExportedDocuments.Remove(doc);
            await _db.SaveChangesAsync(ct);
            return NoContent();
        }

        /// <summary>
        /// Upload côté client d'un document déjà généré (ex: PDF généré dans l'app).
        /// Multipart/form-data avec champ 'file' + éventuellement 'criId', 'exportType'.
        /// </summary>
        [HttpPost("upload")]
        [RequestSizeLimit(50_000_000)]
        public async Task<IActionResult> Upload(
            // Sans [FromForm] : IFormFile est lié au formulaire d'office ([ApiController]),
            // et Swashbuckle 10 refuse l'attribut sur un IFormFile (swagger.json en 500).
            IFormFile file,
            [FromForm] Guid? criId,
            [FromForm] string? exportType,
            CancellationToken ct = default)
        {
            var userId = GetCurrentUserId();
            if (userId == null) return Unauthorized();

            if (file == null || file.Length == 0)
            {
                return BadRequest(new { error = "Fichier vide." });
            }

            var ext = Path.GetExtension(file.FileName).TrimStart('.').ToLowerInvariant();
            if (!AllowedFileTypes.Contains(ext))
            {
                return BadRequest(new { error = $"Type de fichier non supporté: {ext}. Autorisés: pdf, xlsx." });
            }

            using var ms = new MemoryStream();
            await file.CopyToAsync(ms, ct);
            var bytes = ms.ToArray();

            var safeName = Path.GetFileName(file.FileName);
            var objectKey = $"{userId.Value}/{DateTime.UtcNow:yyyy}/{DateTime.UtcNow:MM}/{Guid.NewGuid():N}-{safeName}";

            var contentType = ContentTypes.TryGetValue(ext, out var mime) ? mime : "application/octet-stream";
            await _storage.UploadAsync(objectKey, bytes, contentType, ct);

            var doc = new ExportedDocument
            {
                UserId = userId.Value,
                CriId = criId,
                Filename = Truncate(safeName, 300),
                FileType = ext,
                ExportType = Truncate(string.IsNullOrWhiteSpace(exportType) ? (criId.HasValue ? "cri" : "other") : exportType, 30),
                StoragePath = objectKey,
                SizeBytes = bytes.LongLength,
                CreatedAt = DateTime.UtcNow,
            };

            _db.ExportedDocuments.Add(doc);
            await _db.SaveChangesAsync(ct);

            return Ok(new ExportedDocumentDto
            {
                Id = doc.Id,
                UserId = doc.UserId,
                CriId = doc.CriId,
                Filename = doc.Filename,
                FileType = doc.FileType,
                ExportType = doc.ExportType,
                SizeBytes = doc.SizeBytes,
                CreatedAt = doc.CreatedAt,
            });
        }

        private static string Truncate(string value, int max) =>
            value.Length <= max ? value : value[..max];
    }

    public class RenameRequest
    {
        [Required]
        [MaxLength(300)]
        public string Filename { get; set; } = string.Empty;
    }

    public class ExportedDocumentDto
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string? UserName { get; set; }
        public string? UserEmail { get; set; }
        public Guid? CriId { get; set; }
        public string Filename { get; set; } = string.Empty;
        public string FileType { get; set; } = string.Empty;
        public string ExportType { get; set; } = string.Empty;
        public long SizeBytes { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? SharedAt { get; set; }
        public DateTime? PeriodStart { get; set; }
        public DateTime? PeriodEnd { get; set; }
        public string? Metadata { get; set; }
    }
}
