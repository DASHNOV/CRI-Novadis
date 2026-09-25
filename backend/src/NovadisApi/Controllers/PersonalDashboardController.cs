using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using NovadisApi.Authorization;
using NovadisApi.Models.DTOs;
using NovadisApi.Services.Stats;

namespace NovadisApi.Controllers
{
    /// <summary>
    /// Dashboard du technicien connecté : mêmes calculs que <c>/api/global</c>, périmètre
    /// forcé sur <b>ses</b> CRI (le paramètre <c>technicienId</c> est ignoré).
    /// </summary>
    [ApiController]
    [Route("api/personal/dashboard")]
    [Authorize]
    [Authorize(Policy = Capabilities.PersonalStats)]
    public class PersonalDashboardController : ControllerBase
    {
        private readonly IGlobalStatsService _stats;

        public PersonalDashboardController(IGlobalStatsService stats)
        {
            _stats = stats;
        }

        /// <summary>Filtre de la requête restreint à l'utilisateur connecté, <c>null</c> + réponse d'erreur sinon.</summary>
        private StatsFilter? OwnFilter<T>(StatsQuery query, out ActionResult<ApiResponse<T>>? failure)
        {
            failure = null;
            if (!Guid.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out var userId))
            {
                failure = Unauthorized(ApiResponse<T>.ErrorResponse("Utilisateur non identifié"));
                return null;
            }
            if (!query.TryToFilter(out var filter, out var error))
            {
                failure = BadRequest(ApiResponse<T>.ErrorResponse(error!));
                return null;
            }
            return filter with { TechnicianId = userId };
        }

        /// <summary>GET /api/personal/dashboard/stats?period=30 - KPI (mêmes champs que /api/global/stats)</summary>
        [HttpGet("stats")]
        public async Task<ActionResult<ApiResponse<GlobalStatsDto>>> GetStats(
            [FromQuery] StatsQuery query, CancellationToken ct = default)
        {
            if (OwnFilter<GlobalStatsDto>(query, out var failure) is not { } filter) return failure!;
            return Ok(ApiResponse<GlobalStatsDto>.SuccessResponse(await _stats.GetGlobalStatsAsync(filter, ct)));
        }

        /// <summary>GET /api/personal/dashboard/by-site?period=30</summary>
        [HttpGet("by-site")]
        public async Task<ActionResult<ApiResponse<IEnumerable<SiteStatsDto>>>> GetBySite(
            [FromQuery] StatsQuery query, CancellationToken ct = default)
        {
            if (OwnFilter<IEnumerable<SiteStatsDto>>(query, out var failure) is not { } filter) return failure!;
            return Ok(ApiResponse<IEnumerable<SiteStatsDto>>.SuccessResponse(await _stats.GetStatsBySiteAsync(filter, ct)));
        }

        /// <summary>GET /api/personal/dashboard/evolution?period=30</summary>
        [HttpGet("evolution")]
        public async Task<ActionResult<ApiResponse<EvolutionDto>>> GetEvolution(
            [FromQuery] StatsQuery query, CancellationToken ct = default)
        {
            if (OwnFilter<EvolutionDto>(query, out var failure) is not { } filter) return failure!;
            return Ok(ApiResponse<EvolutionDto>.SuccessResponse(await _stats.GetEvolutionAsync(filter, ct)));
        }

        /// <summary>GET /api/personal/dashboard/recent?limit=10</summary>
        [HttpGet("recent")]
        public async Task<ActionResult<ApiResponse<IEnumerable<RecentInterventionDto>>>> GetRecent(
            [FromQuery] StatsQuery query, [FromQuery] int limit = 10, CancellationToken ct = default)
        {
            if (OwnFilter<IEnumerable<RecentInterventionDto>>(query, out var failure) is not { } filter) return failure!;
            return Ok(ApiResponse<IEnumerable<RecentInterventionDto>>.SuccessResponse(
                await _stats.GetRecentInterventionsAsync(filter, limit, ct)));
        }

        /// <summary>GET /api/personal/dashboard/alerts?period=30&amp;staleDays=14</summary>
        [HttpGet("alerts")]
        public async Task<ActionResult<ApiResponse<DashboardAlertsDto>>> GetAlerts(
            [FromQuery] StatsQuery query, [FromQuery] int staleDays = 14, CancellationToken ct = default)
        {
            if (OwnFilter<DashboardAlertsDto>(query, out var failure) is not { } filter) return failure!;
            return Ok(ApiResponse<DashboardAlertsDto>.SuccessResponse(
                await _stats.GetAlertsAsync(filter, staleDays, ct)));
        }
    }
}
