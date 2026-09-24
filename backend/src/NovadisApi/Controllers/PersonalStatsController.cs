using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NovadisApi.Attributes;
using NovadisApi.Data;
using NovadisApi.Models;
using NovadisApi.Models.DTOs;
using System.Security.Claims;

namespace NovadisApi.Controllers
{
    /// <summary>
    /// 👤 Endpoints personnels - Statistiques et CRI du technicien connecté
    /// Accessible par Technician ET Admin (chacun voit SES propres données)
    /// </summary>
    [ApiController]
    [Route("api/personal")]
    [Authorize]
    [RoleAuthorize("Technician", "Admin")]
    public class PersonalStatsController : ControllerBase
    {
        private readonly NovadisDbContext _context;
        private readonly ILogger<PersonalStatsController> _logger;

        public PersonalStatsController(NovadisDbContext context, ILogger<PersonalStatsController> logger)
        {
            _context = context;
            _logger = logger;
        }

        /// <summary>
        /// Récupère l'ID de l'utilisateur connecté depuis le JWT
        /// </summary>
        private Guid? GetCurrentUserId()
        {
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                ?? User.FindFirst("userId")?.Value;
            if (Guid.TryParse(userIdStr, out var userId))
                return userId;
            return null;
        }

        /// <summary>
        /// 📊 GET /api/personal/stats - Statistiques personnelles du technicien connecté
        /// </summary>
        [HttpGet("stats")]
        public async Task<ActionResult<ApiResponse<PersonalStatsDto>>> GetPersonalStats()
        {
            var userId = GetCurrentUserId();
            if (userId == null)
                return Unauthorized(ApiResponse<PersonalStatsDto>.ErrorResponse("Utilisateur non identifié"));

            try
            {
                var now = DateTime.UtcNow;
                var startOfMonth = new DateTime(now.Year, now.Month, 1);

                var stats = new PersonalStatsDto
                {
                    CriCeMois = await _context.CRIForms
                        .CountAsync(c => c.TechnicianId == userId && c.CreatedAt >= startOfMonth),

                    CriEnCours = await _context.CRIForms
                        .CountAsync(c => c.TechnicianId == userId && c.Status == "Draft"),

                    CriEnAttente = await _context.CRIForms
                        .CountAsync(c => c.TechnicianId == userId && c.ClientSignature == null),

                    // Stats enrichies Phase 1
                    DureeMoyenneMinutes = await _context.CRIForms
                        .Where(c => c.TechnicianId == userId && c.DureeMinutes != null && c.DureeMinutes > 0)
                        .AverageAsync(c => (double?)c.DureeMinutes),

                    TotalResolu = await _context.CRIForms
                        .CountAsync(c => c.TechnicianId == userId && c.ResolutionStatus == "resolu"),

                    TotalNonResolu = await _context.CRIForms
                        .CountAsync(c => c.TechnicianId == userId && (c.ResolutionStatus == "nonResolu" || c.ResolutionStatus == "partiellementResolu")),

                    TotalRecurrenceRequise = await _context.CRIForms
                        .CountAsync(c => c.TechnicianId == userId && c.AdditionalInterventionRequired == true)
                };

                return Ok(ApiResponse<PersonalStatsDto>.SuccessResponse(stats));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving personal stats for user {UserId}", userId);
                return StatusCode(500, ApiResponse<PersonalStatsDto>.ErrorResponse(
                    "Erreur lors de la récupération des statistiques personnelles."));
            }
        }

        /// <summary>
        /// 📋 GET /api/personal/cris - CRI personnels avec filtre
        /// </summary>
        [HttpGet("cris")]
        public async Task<ActionResult<ApiResponse<IEnumerable<CRIForm>>>> GetPersonalCRIs(
            [FromQuery] string filter = "all")
        {
            var userId = GetCurrentUserId();
            if (userId == null)
                return Unauthorized(ApiResponse<IEnumerable<CRIForm>>.ErrorResponse("Utilisateur non identifié"));

            try
            {
                IQueryable<CRIForm> query = _context.CRIForms
                    .Where(c => c.TechnicianId == userId);

                query = filter.ToLower() switch
                {
                    "pending" => query.Where(c => c.ClientSignature == null),
                    "signed" => query.Where(c => c.ClientSignature != null),
                    "in_progress" => query.Where(c => c.Status == "Draft"),
                    _ => query // "all"
                };

                var cris = await query
                    .OrderByDescending(c => c.CreatedAt)
                    .ToListAsync();

                return Ok(ApiResponse<IEnumerable<CRIForm>>.SuccessResponse(cris));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving personal CRIs for user {UserId}", userId);
                return StatusCode(500, ApiResponse<IEnumerable<CRIForm>>.ErrorResponse(
                    "Erreur lors de la récupération des CRI personnels."));
            }
        }

        /// <summary>
        /// 🕐 GET /api/personal/recent - 5 derniers CRI du technicien
        /// </summary>
        [HttpGet("recent")]
        public async Task<ActionResult<ApiResponse<IEnumerable<CRIForm>>>> GetRecentCRIs()
        {
            var userId = GetCurrentUserId();
            if (userId == null)
                return Unauthorized(ApiResponse<IEnumerable<CRIForm>>.ErrorResponse("Utilisateur non identifié"));

            try
            {
                var recentCris = await _context.CRIForms
                    .Where(c => c.TechnicianId == userId)
                    .OrderByDescending(c => c.CreatedAt)
                    .Take(5)
                    .ToListAsync();

                return Ok(ApiResponse<IEnumerable<CRIForm>>.SuccessResponse(recentCris));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving recent CRIs for user {UserId}", userId);
                return StatusCode(500, ApiResponse<IEnumerable<CRIForm>>.ErrorResponse(
                    "Erreur lors de la récupération des CRI récents."));
            }
        }

        /// <summary>
        /// 📅 GET /api/personal/daily-stats - Activité journalière sur les 365 derniers jours
        /// </summary>
        [HttpGet("daily-stats")]
        public async Task<ActionResult<ApiResponse<IEnumerable<object>>>> GetDailyStats([FromQuery] int? year = null)
        {
            var userId = GetCurrentUserId();
            if (userId == null)
                return Unauthorized(ApiResponse<IEnumerable<object>>.ErrorResponse("Utilisateur non identifié"));

            try
            {
                var today = DateTime.UtcNow.Date;
                DateTime startDate;
                DateTime endDate;

                if (year.HasValue && year.Value != today.Year)
                {
                    startDate = new DateTime(year.Value, 1, 1);
                    endDate = new DateTime(year.Value, 12, 31);
                }
                else
                {
                    endDate = today;
                    startDate = today.AddDays(-364);
                }

                var dailyCounts = await _context.CRIForms
                    .Where(c => c.TechnicianId == userId && c.CreatedAt >= startDate && c.CreatedAt <= endDate.AddDays(1))
                    .GroupBy(c => c.CreatedAt.Date)
                    .Select(g => new { jour = g.Key, nb = g.Count() })
                    .ToListAsync();

                var lookup = dailyCounts.ToDictionary(d => d.jour, d => d.nb);
                var totalDays = (endDate - startDate).Days + 1;

                var result = Enumerable.Range(0, totalDays)
                    .Select(i => {
                        var d = startDate.AddDays(i);
                        return new { jour = d.ToString("yyyy-MM-dd"), nb = lookup.TryGetValue(d, out var nb) ? nb : 0 };
                    })
                    .ToList();

                return Ok(ApiResponse<IEnumerable<object>>.SuccessResponse(result.Cast<object>()));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving daily stats for user {UserId}", userId);
                return StatusCode(500, ApiResponse<IEnumerable<object>>.ErrorResponse(
                    "Erreur lors de la récupération des statistiques journalières."));
            }
        }

        /// <summary>
        /// 📈 GET /api/personal/monthly-stats - Activité mensuelle sur les 6 derniers mois
        /// </summary>
        [HttpGet("monthly-stats")]
        public async Task<ActionResult<ApiResponse<IEnumerable<object>>>> GetMonthlyStats()
        {
            var userId = GetCurrentUserId();
            if (userId == null)
                return Unauthorized(ApiResponse<IEnumerable<object>>.ErrorResponse("Utilisateur non identifié"));

            try
            {
                var now = DateTime.UtcNow;
                var sixMonthsAgo = new DateTime(now.Year, now.Month, 1).AddMonths(-5);

                var monthlyCounts = await _context.CRIForms
                    .Where(c => c.TechnicianId == userId && c.CreatedAt >= sixMonthsAgo)
                    .GroupBy(c => new { c.CreatedAt.Year, c.CreatedAt.Month })
                    .Select(g => new { annee = g.Key.Year, mois = g.Key.Month, nb = g.Count() })
                    .ToListAsync();

                // Garantir les 6 mois même si nb = 0
                var result = Enumerable.Range(0, 6)
                    .Select(i => {
                        var d = new DateTime(now.Year, now.Month, 1).AddMonths(-5 + i);
                        var found = monthlyCounts.FirstOrDefault(m => m.annee == d.Year && m.mois == d.Month);
                        return new { annee = d.Year, mois = d.Month, nb = found?.nb ?? 0 };
                    })
                    .ToList();

                return Ok(ApiResponse<IEnumerable<object>>.SuccessResponse(result.Cast<object>()));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving monthly stats for user {UserId}", userId);
                return StatusCode(500, ApiResponse<IEnumerable<object>>.ErrorResponse(
                    "Erreur lors de la récupération des statistiques mensuelles."));
            }
        }
    }
}
