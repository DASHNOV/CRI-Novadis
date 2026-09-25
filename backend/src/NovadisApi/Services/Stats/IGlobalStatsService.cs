using NovadisApi.Models.DTOs;

namespace NovadisApi.Services.Stats;

/// <summary>
/// Logique métier pour les statistiques globales (dashboard admin).
/// </summary>
public interface IGlobalStatsService
{
    Task<GlobalStatsDto> GetGlobalStatsAsync(StatsFilter filter, CancellationToken ct = default);

    Task<IReadOnlyList<CRIWithTechnicianDto>> GetAllCRIsWithTechnicianAsync(
        Guid? technicienId, string filter, string? searchId, CancellationToken ct = default);

    Task<IReadOnlyList<TechnicianActivityDto>> GetTechnicianActivityAsync(CancellationToken ct = default);

    Task<IReadOnlyList<DailyActivityDto>> GetActivityChartDataAsync(CancellationToken ct = default);

    Task<IReadOnlyList<UserDto>> GetTechniciansAsync(CancellationToken ct = default);

    Task<IReadOnlyList<SiteStatsDto>> GetStatsBySiteAsync(StatsFilter filter, CancellationToken ct = default);

    Task<IReadOnlyList<TechnicianDetailedStatsDto>> GetStatsByTechnicianAsync(StatsFilter filter, CancellationToken ct = default);

    Task<DistributionStatsDto> GetDistributionStatsAsync(StatsFilter filter, CancellationToken ct = default);

    /// <summary>Nombre d'interventions par jour, semaine ou mois selon la durée couverte.</summary>
    Task<EvolutionDto> GetEvolutionAsync(StatsFilter filter, CancellationToken ct = default);

    /// <summary>Dernières interventions (date d'intervention décroissante), 1 à 100.</summary>
    Task<IReadOnlyList<RecentInterventionDto>> GetRecentInterventionsAsync(
        StatsFilter filter, int limit, CancellationToken ct = default);
}
