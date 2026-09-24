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
        /// GET /api/global/stats?period=30 - Statistiques globales
        /// </summary>
        [HttpGet("stats")]
        public async Task<ActionResult<ApiResponse<GlobalStatsDto>>> GetGlobalStats(
            [FromQuery] int? period = null, CancellationToken ct = default)
        {
            var data = await _stats.GetGlobalStatsAsync(period, ct);
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
            [FromQuery] int? period = null, CancellationToken ct = default)
        {
            var data = await _stats.GetStatsBySiteAsync(period, ct);
            return Ok(ApiResponse<IEnumerable<SiteStatsDto>>.SuccessResponse(data));
        }

        /// <summary>GET /api/global/stats/by-technician?period=30 - Stats par technicien</summary>
        [HttpGet("stats/by-technician")]
        public async Task<ActionResult<ApiResponse<IEnumerable<TechnicianDetailedStatsDto>>>> GetStatsByTechnician(
            [FromQuery] int? period = null, CancellationToken ct = default)
        {
            var data = await _stats.GetStatsByTechnicianAsync(period, ct);
            return Ok(ApiResponse<IEnumerable<TechnicianDetailedStatsDto>>.SuccessResponse(data));
        }

        /// <summary>GET /api/global/stats/distribution?period=30 - Statistiques croisées</summary>
        [HttpGet("stats/distribution")]
        public async Task<ActionResult<ApiResponse<DistributionStatsDto>>> GetDistributionStats(
            [FromQuery] int? period = null, CancellationToken ct = default)
        {
            var data = await _stats.GetDistributionStatsAsync(period, ct);
            return Ok(ApiResponse<DistributionStatsDto>.SuccessResponse(data));
        }
    }
}
