using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NovadisApi.Data;
using NovadisApi.Models;
using NovadisApi.Models.DTOs;
using NovadisApi.Services;
using System.Security.Claims;
using System.Text.Json;

namespace NovadisApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class CRIController : ControllerBase
    {
        private readonly NovadisDbContext _context;
        private readonly ILogger<CRIController> _logger;
        private readonly IWebHostEnvironment _env;
        private readonly ISiteSummaryService _siteSummaryService;

        private static readonly string[] AllowedMimeTypes = ["image/jpeg", "image/jpg", "image/png", "image/webp"];

        public CRIController(NovadisDbContext context, ILogger<CRIController> logger, IWebHostEnvironment env, ISiteSummaryService siteSummaryService)
        {
            _context = context;
            _logger = logger;
            _env = env;
            _siteSummaryService = siteSummaryService;
        }

        private string GetPhotosDirectory(Guid criId)
        {
            var dir = Path.Combine(_env.ContentRootPath, "uploads", "cri-photos", criId.ToString());
            Directory.CreateDirectory(dir);
            return dir;
        }

        private Guid? GetCurrentUserId()
        {
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                ?? User.FindFirst("userId")?.Value;
            if (Guid.TryParse(userIdStr, out var userId))
                return userId;
            return null;
        }

        [HttpGet]
        public async Task<ActionResult<ApiResponse<IEnumerable<CRIForm>>>> GetMyCRIs(
            [FromQuery] int? page = null,
            [FromQuery] int? pageSize = null)
        {
            var userId = GetCurrentUserId();
            if (userId == null)
                return Unauthorized(ApiResponse<IEnumerable<CRIForm>>.ErrorResponse("Utilisateur non identifié"));

            IQueryable<CRIForm> query = _context.CRIForms.AsNoTracking();

            if (!User.IsInRole("Admin"))
            {
                query = query.Where(c => c.TechnicianId == userId.Value);
            }

            query = query.OrderByDescending(c => c.CreatedAt);

            // Pagination optionnelle (rétrocompatible : sans ?page= → tout retourné comme avant)
            List<CRIForm> cris;
            if (page.HasValue || pageSize.HasValue)
            {
                var pagination = new PaginationQuery
                {
                    Page = page ?? 1,
                    PageSize = pageSize ?? 50
                };
                var total = await query.CountAsync();
                cris = await query.Skip(pagination.Skip).Take(pagination.PageSize).ToListAsync();

                Response.Headers["X-Total-Count"] = total.ToString();
                Response.Headers["X-Page"] = pagination.Page.ToString();
                Response.Headers["X-Page-Size"] = pagination.PageSize.ToString();
                Response.Headers["X-Total-Pages"] =
                    ((int)Math.Ceiling((double)total / pagination.PageSize)).ToString();
            }
            else
            {
                cris = await query.ToListAsync();
            }

            return Ok(ApiResponse<IEnumerable<CRIForm>>.SuccessResponse(cris));
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<ApiResponse<CRIForm>>> GetCRI(Guid id)
        {
            var userId = GetCurrentUserId();
            if (userId == null)
                return Unauthorized(ApiResponse<CRIForm>.ErrorResponse("Utilisateur non identifié"));

            var cri = await _context.CRIForms
                .Include(c => c.Photos)
                .FirstOrDefaultAsync(c => c.Id == id);

            if (cri == null)
                return NotFound(ApiResponse<CRIForm>.ErrorResponse("CRI introuvable"));

            // Les admins peuvent tout voir, les techniciens seulement les leurs
            if (cri.TechnicianId != userId.Value && !User.IsInRole("Admin"))
                return Forbid();

            return Ok(ApiResponse<CRIForm>.SuccessResponse(cri));
        }

        [HttpPost]
        public async Task<ActionResult<ApiResponse<CRIForm>>> CreateCRI([FromBody] CRIForm cri)
        {
            var userId = GetCurrentUserId();
            if (userId == null)
                return Unauthorized(ApiResponse<CRIForm>.ErrorResponse("Utilisateur non identifié"));

            cri.Id = cri.Id == Guid.Empty ? Guid.NewGuid() : cri.Id;

            var existing = await _context.CRIForms.FindAsync(cri.Id);
            if (existing != null)
            {
                // CRI already exists on server (e.g. draft saved before) — update it
                if (existing.TechnicianId != userId.Value && !User.IsInRole("Admin"))
                    return Forbid();

                existing.InterventionType = cri.InterventionType;
                existing.Category = cri.Category;
                existing.InterventionDate = cri.InterventionDate;
                existing.ClientName = cri.ClientName;
                existing.ClientAddress = cri.ClientAddress;
                existing.ClientPhone = cri.ClientPhone;
                existing.ClientEmail = cri.ClientEmail;
                existing.WorkDescription = cri.WorkDescription;
                existing.MaterialsUsed = cri.MaterialsUsed;
                existing.Duration = cri.Duration;
                existing.Status = cri.Status;
                existing.Data = cri.Data;
                existing.TechnicianSignature = cri.TechnicianSignature;
                existing.ClientSignature = cri.ClientSignature;
                existing.UpdatedAt = DateTime.UtcNow;

                ExtractDataFields(existing);
                await ResolveRelations(existing);

                if (existing.Status == "Submitted" && existing.SubmittedAt == null)
                    existing.SubmittedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();
                _siteSummaryService.InvalidateSiteSummary(existing.ClientSite);
                return Ok(ApiResponse<CRIForm>.SuccessResponse(existing));
            }

            cri.TechnicianId = userId.Value;
            cri.CreatedAt = DateTime.UtcNow;

            ExtractDataFields(cri);
            await ResolveRelations(cri);

            _context.CRIForms.Add(cri);
            await _context.SaveChangesAsync();
            _siteSummaryService.InvalidateSiteSummary(cri.ClientSite);
            return CreatedAtAction(nameof(GetCRI), new { id = cri.Id }, ApiResponse<CRIForm>.SuccessResponse(cri));
        }

        [HttpPut("{id}")]
        public async Task<ActionResult<ApiResponse<CRIForm>>> UpdateCRI(Guid id, [FromBody] CRIForm criUpdate)
        {
            var userId = GetCurrentUserId();
            if (userId == null)
                return Unauthorized(ApiResponse<CRIForm>.ErrorResponse("Utilisateur non identifié"));

            var cri = await _context.CRIForms.FindAsync(id);

            if (cri == null)
                return NotFound(ApiResponse<CRIForm>.ErrorResponse("CRI introuvable"));

            var isOwner = cri.TechnicianId == userId.Value;
            var alreadySubmitted = cri.Status == "Submitted";

            if (alreadySubmitted)
            {
                // Un CRI déjà soumis ne peut être modifié que par son propriétaire
                // (pas de dérogation Admin sur l'édition post-soumission).
                if (!isOwner)
                    return Forbid();
            }
            else
            {
                // Brouillon / CRI non soumis : propriétaire ou administrateur.
                if (!isOwner && !User.IsInRole("Admin"))
                    return Forbid();
            }

            // Mise à jour des champs
            cri.InterventionType = criUpdate.InterventionType;
            cri.Category = criUpdate.Category;
            cri.InterventionDate = criUpdate.InterventionDate;
            cri.ClientName = criUpdate.ClientName;
            cri.ClientAddress = criUpdate.ClientAddress;
            cri.ClientPhone = criUpdate.ClientPhone;
            cri.ClientEmail = criUpdate.ClientEmail;
            cri.WorkDescription = criUpdate.WorkDescription;
            cri.MaterialsUsed = criUpdate.MaterialsUsed;
            cri.Duration = criUpdate.Duration;
            cri.Status = criUpdate.Status;
            cri.Data = criUpdate.Data;
            cri.TechnicianSignature = criUpdate.TechnicianSignature;
            cri.ClientSignature = criUpdate.ClientSignature;
            cri.UpdatedAt = DateTime.UtcNow;

            ExtractDataFields(cri);
            await ResolveRelations(cri);

            if (cri.Status == "Submitted" && cri.SubmittedAt == null)
            {
                cri.SubmittedAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();
            _siteSummaryService.InvalidateSiteSummary(cri.ClientSite);
            return Ok(ApiResponse<CRIForm>.SuccessResponse(cri));
        }

        /// <summary>
        /// PATCH /api/cri/{id}/signature - Toggle la signature client (validation manuelle).
        /// Seul le propriétaire du CRI peut effectuer cette action — les admins ne
        /// peuvent le faire que sur leurs propres CRI.
        /// </summary>
        [HttpPatch("{id}/signature")]
        public async Task<ActionResult<ApiResponse<object>>> UpdateClientSignature(Guid id, [FromBody] UpdateSignatureDto body)
        {
            var userId = GetCurrentUserId();
            if (userId == null)
                return Unauthorized(ApiResponse<object>.ErrorResponse("Utilisateur non identifié"));

            var cri = await _context.CRIForms.FindAsync(id);
            if (cri == null)
                return NotFound(ApiResponse<object>.ErrorResponse("CRI introuvable"));

            // Strict ownership — pas de bypass admin.
            if (cri.TechnicianId != userId.Value)
                return Forbid();

            cri.ClientSignature = body.ClientSignature;
            cri.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(ApiResponse<object>.SuccessResponse(
                new { id = cri.Id, clientSignature = cri.ClientSignature },
                "Signature mise à jour"));
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult<ApiResponse<object>>> DeleteCRI(Guid id)
        {
            var userId = GetCurrentUserId();
            if (userId == null)
                return Unauthorized(ApiResponse<object>.ErrorResponse("Utilisateur non identifié"));

            var cri = await _context.CRIForms.FindAsync(id);

            if (cri == null)
                return NotFound(ApiResponse<object>.ErrorResponse("CRI introuvable"));

            if (cri.TechnicianId != userId.Value && !User.IsInRole("Admin"))
                return Forbid();

            _context.CRIForms.Remove(cri);
            await _context.SaveChangesAsync();

            return Ok(ApiResponse<object>.SuccessResponse(null, "CRI supprimé avec succès"));
        }

        [HttpGet("clients/search")]
        public async Task<ActionResult<ApiResponse<IEnumerable<string>>>> SearchClients([FromQuery] string q)
        {
            if (string.IsNullOrWhiteSpace(q))
                return Ok(ApiResponse<IEnumerable<string>>.SuccessResponse(new List<string>()));
            
            var query = q.ToLower();
            var clients = await _context.CRIForms
                .Where(c => c.ClientName != null && c.ClientName.ToLower().Contains(query))
                .Select(c => c.ClientName)
                .Distinct()
                .OrderBy(c => c)
                .Take(20)
                .ToListAsync();

            return Ok(ApiResponse<IEnumerable<string>>.SuccessResponse(clients!));
        }

        [HttpGet("sites/search")]
        public async Task<ActionResult<ApiResponse<IEnumerable<string>>>> SearchSites([FromQuery] string? client, [FromQuery] string q)
        {
            var queryDb = _context.CRIForms.AsQueryable();

            if (!string.IsNullOrWhiteSpace(client))
            {
               var loweredClient = client.ToLower();
               queryDb = queryDb.Where(c => c.ClientName != null && c.ClientName.ToLower() == loweredClient);
            }

            if (!string.IsNullOrWhiteSpace(q))
            {
               var loweredQ = q.ToLower();
               queryDb = queryDb.Where(c => c.ClientSite != null && c.ClientSite.ToLower().Contains(loweredQ));
            }

            var sites = await queryDb
                .Where(c => c.ClientSite != null)
                .Select(c => c.ClientSite)
                .Distinct()
                .OrderBy(c => c)
                .Take(20)
                .ToListAsync();

            return Ok(ApiResponse<IEnumerable<string>>.SuccessResponse(sites!));
        }

        /// <summary>
        /// POST /api/cri/{id}/photos — Upload de photos (multipart/form-data, champ "files").
        /// </summary>
        [HttpPost("{id}/photos")]
        [Consumes("multipart/form-data")]
        [RequestSizeLimit(52_428_800)] // 50 MB max
        public async Task<ActionResult<ApiResponse<List<CRIPhoto>>>> UploadPhotos(Guid id)
        {
            var userId = GetCurrentUserId();
            if (userId == null)
                return Unauthorized(ApiResponse<List<CRIPhoto>>.ErrorResponse("Utilisateur non identifié"));

            var cri = await _context.CRIForms.FindAsync(id);
            if (cri == null)
                return NotFound(ApiResponse<List<CRIPhoto>>.ErrorResponse("CRI introuvable"));

            if (cri.TechnicianId != userId.Value && !User.IsInRole("Admin"))
                return Forbid();

            var files = Request.Form.Files;
            if (files.Count == 0)
                return BadRequest(ApiResponse<List<CRIPhoto>>.ErrorResponse("Aucun fichier fourni"));

            var photosDir = GetPhotosDirectory(id);
            var created = new List<CRIPhoto>();

            foreach (var file in files)
            {
                if (file.Length == 0 || file.Length > 10 * 1024 * 1024) continue;

                var mime = file.ContentType?.ToLower() ?? string.Empty;
                if (!AllowedMimeTypes.Contains(mime)) continue;

                var ext = mime switch
                {
                    "image/png" => ".png",
                    "image/webp" => ".webp",
                    _ => ".jpg"
                };

                var photoId = Guid.NewGuid();
                var filePath = Path.Combine(photosDir, $"{photoId}{ext}");

                await using (var stream = new FileStream(filePath, FileMode.Create))
                    await file.CopyToAsync(stream);

                var photo = new CRIPhoto
                {
                    Id = photoId,
                    CRIFormId = id,
                    StoragePath = filePath,
                    OriginalFileName = file.FileName,
                    MimeType = mime,
                    FileSize = file.Length,
                    UploadedAt = DateTime.UtcNow
                };

                _context.CRIPhotos.Add(photo);
                created.Add(photo);
            }

            await _context.SaveChangesAsync();
            return Ok(ApiResponse<List<CRIPhoto>>.SuccessResponse(created));
        }

        /// <summary>
        /// GET /api/cri/{id}/photos/{photoId} — Sert le fichier image (authentifié).
        /// </summary>
        [HttpGet("{id}/photos/{photoId}")]
        public async Task<IActionResult> GetPhoto(Guid id, Guid photoId)
        {
            var userId = GetCurrentUserId();
            if (userId == null) return Unauthorized();

            var photo = await _context.CRIPhotos
                .Include(p => p.CRIForm)
                .FirstOrDefaultAsync(p => p.Id == photoId && p.CRIFormId == id);

            if (photo == null) return NotFound();

            if (photo.CRIForm!.TechnicianId != userId.Value && !User.IsInRole("Admin"))
                return Forbid();

            if (!System.IO.File.Exists(photo.StoragePath))
                return NotFound();

            return PhysicalFile(photo.StoragePath, photo.MimeType ?? "image/jpeg");
        }

        /// <summary>
        /// DELETE /api/cri/{id}/photos/{photoId} — Supprime une photo (fichier + BDD).
        /// </summary>
        [HttpDelete("{id}/photos/{photoId}")]
        public async Task<ActionResult<ApiResponse<object>>> DeletePhoto(Guid id, Guid photoId)
        {
            var userId = GetCurrentUserId();
            if (userId == null)
                return Unauthorized(ApiResponse<object>.ErrorResponse("Utilisateur non identifié"));

            var photo = await _context.CRIPhotos
                .Include(p => p.CRIForm)
                .FirstOrDefaultAsync(p => p.Id == photoId && p.CRIFormId == id);

            if (photo == null)
                return NotFound(ApiResponse<object>.ErrorResponse("Photo introuvable"));

            if (photo.CRIForm!.TechnicianId != userId.Value && !User.IsInRole("Admin"))
                return Forbid();

            if (System.IO.File.Exists(photo.StoragePath))
                System.IO.File.Delete(photo.StoragePath);

            _context.CRIPhotos.Remove(photo);
            await _context.SaveChangesAsync();

            return Ok(ApiResponse<object>.SuccessResponse(null, "Photo supprimée"));
        }

        /// <summary>
        /// Résout les relations normalisées : ClientSite → SiteID, ClientName → ClientID.
        /// Si le client n'existe pas, il est créé automatiquement.
        /// </summary>
        private async Task ResolveRelations(CRIForm cri)
        {
            // ── Résolution Site ──
            if (!string.IsNullOrWhiteSpace(cri.ClientSite))
            {
                var siteName = cri.ClientSite.Trim();
                var site = await _context.Sites
                    .FirstOrDefaultAsync(s => s.NomDuSite == siteName);
                cri.SiteID = site?.Numero;
            }

            // ── Résolution Client (lookup ou auto-création) ──
            if (!string.IsNullOrWhiteSpace(cri.ClientName))
            {
                var clientName = cri.ClientName.Trim();
                var client = await _context.ClientsNormalises
                    .FirstOrDefaultAsync(c => c.RaisonSociale == clientName);

                if (client == null)
                {
                    client = new Client
                    {
                        Id = Guid.NewGuid(),
                        RaisonSociale = clientName,
                        Contact = cri.ClientContact,
                        Telephone = cri.ClientPhone,
                        Email = cri.ClientEmail,
                        Adresse = cri.ClientAddress,
                        CodePostal = cri.CodePostal,
                        Ville = cri.Ville,
                        Pays = cri.Pays,
                        CreatedAt = DateTime.UtcNow
                    };
                    _context.ClientsNormalises.Add(client);
                }
                else
                {
                    // Mettre à jour les coordonnées si plus récentes
                    if (!string.IsNullOrWhiteSpace(cri.ClientContact))
                        client.Contact = cri.ClientContact;
                    if (!string.IsNullOrWhiteSpace(cri.ClientPhone))
                        client.Telephone = cri.ClientPhone;
                    if (!string.IsNullOrWhiteSpace(cri.ClientEmail))
                        client.Email = cri.ClientEmail;
                    if (!string.IsNullOrWhiteSpace(cri.ClientAddress))
                        client.Adresse = cri.ClientAddress;
                    if (!string.IsNullOrWhiteSpace(cri.Ville))
                        client.Ville = cri.Ville;
                    client.UpdatedAt = DateTime.UtcNow;
                }

                cri.ClientID = client.Id;
            }
        }

        /// <summary>
        /// Extrait les champs statistiques du JSON Data vers les colonnes typées.
        /// Le JSON Data est envoyé par le frontend (jsonEncode du modèle Dart complet).
        /// </summary>
        private void ExtractDataFields(CRIForm cri)
        {
            if (string.IsNullOrWhiteSpace(cri.Data))
                return;

            try
            {
                using var doc = JsonDocument.Parse(cri.Data);
                var root = doc.RootElement;

                // Horaires
                if (root.TryGetProperty("startTime", out var startTime) && startTime.ValueKind == JsonValueKind.String)
                {
                    if (DateTime.TryParse(startTime.GetString(), out var dt))
                        cri.HeureDebut = dt.TimeOfDay;
                }
                if (root.TryGetProperty("endTime", out var endTime) && endTime.ValueKind == JsonValueKind.String)
                {
                    if (DateTime.TryParse(endTime.GetString(), out var dt))
                        cri.HeureFin = dt.TimeOfDay;
                }

                // Durée : utiliser interventionDurationMinutes (Service) ou calculer depuis start/end (Projet)
                if (root.TryGetProperty("interventionDurationMinutes", out var durationProp) && durationProp.ValueKind == JsonValueKind.Number)
                {
                    cri.DureeMinutes = durationProp.GetInt32();
                }
                else if (cri.HeureDebut.HasValue && cri.HeureFin.HasValue)
                {
                    cri.DureeMinutes = (int)(cri.HeureFin.Value - cri.HeureDebut.Value).TotalMinutes;
                }

                // Localisation client
                cri.Ville = GetStringOrNull(root, "ville");
                cri.CodePostal = GetStringOrNull(root, "codePostal");
                cri.Pays = GetStringOrNull(root, "pays");
                cri.ClientContact = GetStringOrNull(root, "clientContact");

                // Champs Service
                cri.TicketNumber = GetStringOrNull(root, "ticketNumber");
                cri.ResolutionStatus = GetStringOrNull(root, "resolutionStatus");

                if (root.TryGetProperty("additionalInterventionRequired", out var addIntProp))
                {
                    if (addIntProp.ValueKind == JsonValueKind.True || addIntProp.ValueKind == JsonValueKind.False)
                        cri.AdditionalInterventionRequired = addIntProp.GetBoolean();
                    else if (addIntProp.ValueKind == JsonValueKind.Number)
                        cri.AdditionalInterventionRequired = addIntProp.GetInt32() == 1;
                }

                // Champs Projet
                cri.ProjectName = GetStringOrNull(root, "projectName");
                cri.ProjectNumber = GetStringOrNull(root, "projectNumber");
                cri.ProjectPhase = GetStringOrNull(root, "projectPhase");
                cri.ProjectStatus = GetStringOrNull(root, "projectStatus");
            }
            catch (JsonException ex)
            {
                _logger.LogWarning(ex, "Impossible de parser le champ Data du CRI {CriId}", cri.Id);
            }
        }

        private static string? GetStringOrNull(JsonElement root, string propertyName)
        {
            if (root.TryGetProperty(propertyName, out var prop) && prop.ValueKind == JsonValueKind.String)
            {
                var value = prop.GetString();
                return string.IsNullOrWhiteSpace(value) ? null : value;
            }
            return null;
        }
    }
}
