using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using NovadisApi.Models.DTOs;
using NovadisApi.Services.Stats;
using NovadisApi.Authorization;

namespace NovadisApi.Controllers
{
    /// <summary>
    /// 🌐 Endpoints globaux - Dashboard et statistiques globales
    /// ⚠️ Accessible uniquement par les Admin
    /// </summary>
    [ApiController]
    [Route("api/global")]
    [Authorize]
    [Authorize(Policy = Capabilities.GlobalStats)]
    public class GlobalStatsController : ControllerBase
    {
        private readonly IGlobalStatsService _stats;

        public GlobalStatsController(IGlobalStatsService stats)
        {
            _stats = stats;
        }

        /// <summary>
        /// GET /api/global/stats?period=30 | from=&amp;to= [&amp;technicienId=&amp;site=] - Statistiques globales
        /// </summary>
        [HttpGet("stats")]
        public async Task<ActionResult<ApiResponse<GlobalStatsDto>>> GetGlobalStats(
            [FromQuery] StatsQuery query, CancellationToken ct = default)
        {
            if (!query.TryToFilter(out var filter, out var error))
                return BadRequest(ApiResponse<GlobalStatsDto>.ErrorResponse(error!));
            var data = await _stats.GetGlobalStatsAsync(filter, ct);
            return Ok(ApiResponse<GlobalStatsDto>.SuccessResponse(data));
        }

        /// <summary>📋 GET /api/global/cris - Tous les CRI avec info technicien</summary>
        [HttpGet("cris")]
        public async Task<ActionResult<ApiResponse<IEnumerable<CRIWithTechnicianDto>>>> GetAllCRIsWithTechnician(
            [FromQuery] Guid? technicienId = null,
            [FromQuery] string filter = "all",
            [FromQuery] string? searchId = null,
            CancellationToken ct = default)
        {
            var data = await _stats.GetAllCRIsWithTechnicianAsync(technicienId, filter, searchId, ct);
            return Ok(ApiResponse<IEnumerable<CRIWithTechnicianDto>>.SuccessResponse(data));
        }

        /// <summary>👥 GET /api/global/activity - Activité de tous les techniciens</summary>
        [HttpGet("activity")]
        public async Task<ActionResult<ApiResponse<IEnumerable<TechnicianActivityDto>>>> GetTechnicianActivity(CancellationToken ct = default)
        {
            var data = await _stats.GetTechnicianActivityAsync(ct);
            return Ok(ApiResponse<IEnumerable<TechnicianActivityDto>>.SuccessResponse(data));
        }

        /// <summary>📈 GET /api/global/activity-chart - Données graphique activité 7j</summary>
        [HttpGet("activity-chart")]
        public async Task<ActionResult<ApiResponse<IEnumerable<DailyActivityDto>>>> GetActivityChartData(CancellationToken ct = default)
        {
            var data = await _stats.GetActivityChartDataAsync(ct);
            return Ok(ApiResponse<IEnumerable<DailyActivityDto>>.SuccessResponse(data));
        }

        /// <summary>👥 GET /api/global/technicians - Liste des techniciens</summary>
        [HttpGet("technicians")]
        public async Task<ActionResult<ApiResponse<IEnumerable<UserDto>>>> GetTechnicians(CancellationToken ct = default)
        {
            var data = await _stats.GetTechniciansAsync(ct);
            return Ok(ApiResponse<IEnumerable<UserDto>>.SuccessResponse(data));
        }

        /// <summary>GET /api/global/stats/by-site?period=30 - Stats par site</summary>
        [HttpGet("stats/by-site")]
        public async Task<ActionResult<ApiResponse<IEnumerable<SiteStatsDto>>>> GetStatsBySite(
            [FromQuery] StatsQuery query, CancellationToken ct = default)
        {
            if (!query.TryToFilter(out var filter, out var error))
                return BadRequest(ApiResponse<IEnumerable<SiteStatsDto>>.ErrorResponse(error!));
            var data = await _stats.GetStatsBySiteAsync(filter, ct);
            return Ok(ApiResponse<IEnumerable<SiteStatsDto>>.SuccessResponse(data));
        }

        /// <summary>GET /api/global/stats/by-technician?period=30 - Stats par technicien</summary>
        [HttpGet("stats/by-technician")]
        public async Task<ActionResult<ApiResponse<IEnumerable<TechnicianDetailedStatsDto>>>> GetStatsByTechnician(
            [FromQuery] StatsQuery query, CancellationToken ct = default)
        {
            if (!query.TryToFilter(out var filter, out var error))
                return BadRequest(ApiResponse<IEnumerable<TechnicianDetailedStatsDto>>.ErrorResponse(error!));
            var data = await _stats.GetStatsByTechnicianAsync(filter, ct);
            return Ok(ApiResponse<IEnumerable<TechnicianDetailedStatsDto>>.SuccessResponse(data));
        }

        /// <summary>GET /api/global/stats/distribution?period=30 - Statistiques croisées</summary>
        [HttpGet("stats/distribution")]
        public async Task<ActionResult<ApiResponse<DistributionStatsDto>>> GetDistributionStats(
            [FromQuery] StatsQuery query, CancellationToken ct = default)
        {
            if (!query.TryToFilter(out var filter, out var error))
                return BadRequest(ApiResponse<DistributionStatsDto>.ErrorResponse(error!));
            var data = await _stats.GetDistributionStatsAsync(filter, ct);
            return Ok(ApiResponse<DistributionStatsDto>.SuccessResponse(data));
        }

        /// <summary>GET /api/global/stats/evolution?period=30 - Courbe d'activité (jour / semaine / mois)</summary>
        [HttpGet("stats/evolution")]
        public async Task<ActionResult<ApiResponse<EvolutionDto>>> GetEvolution(
            [FromQuery] StatsQuery query, CancellationToken ct = default)
        {
            if (!query.TryToFilter(out var filter, out var error))
                return BadRequest(ApiResponse<EvolutionDto>.ErrorResponse(error!));
            var data = await _stats.GetEvolutionAsync(filter, ct);
            return Ok(ApiResponse<EvolutionDto>.SuccessResponse(data));
        }

        /// <summary>GET /api/global/stats/recent?limit=10 - Dernières interventions</summary>
        [HttpGet("stats/recent")]
        public async Task<ActionResult<ApiResponse<IEnumerable<RecentInterventionDto>>>> GetRecent(
            [FromQuery] StatsQuery query, [FromQuery] int limit = 10, CancellationToken ct = default)
        {
            if (!query.TryToFilter(out var filter, out var error))
                return BadRequest(ApiResponse<IEnumerable<RecentInterventionDto>>.ErrorResponse(error!));
            var data = await _stats.GetRecentInterventionsAsync(filter, limit, ct);
            return Ok(ApiResponse<IEnumerable<RecentInterventionDto>>.SuccessResponse(data));
        }
    }
}
