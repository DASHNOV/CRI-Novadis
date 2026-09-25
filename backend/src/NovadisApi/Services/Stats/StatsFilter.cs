using NovadisApi.Models;

namespace NovadisApi.Services.Stats;

/// <summary>
/// Périmètre d'une statistique : période sur la date d'intervention, et
/// éventuellement un technicien et / ou un site. Toutes les méthodes de
/// <see cref="IGlobalStatsService"/> le reçoivent : un seul endroit filtre.
/// </summary>
/// <remarks>
/// Les dates d'intervention sont saisies à la journée (minuit) : les bornes
/// sont des dates, <see cref="From"/> incluse, <see cref="To"/> exclue. Ne jamais
/// filtrer « maintenant moins n jours » : le premier jour serait coupé.
/// </remarks>
public sealed record StatsFilter
{
    /// <summary>Première journée incluse (minuit), <c>null</c> : depuis le début.</summary>
    public DateTime? From { get; init; }

    /// <summary>Borne exclue (minuit du lendemain de la dernière journée), <c>null</c> : sans limite.</summary>
    public DateTime? To { get; init; }

    /// <summary>Auteur des CRI (<see cref="CRIForm.TechnicianId"/>).</summary>
    public Guid? TechnicianId { get; init; }

    /// <summary>Nom du site, tel que regroupé par les stats par site (site normalisé, sinon saisie libre).</summary>
    public string? Site { get; init; }

    /// <summary>Toute la base.</summary>
    public static StatsFilter All { get; } = new();

    /// <summary>
    /// Les <paramref name="days"/> derniers jours, aujourd'hui compris. Sans borne haute :
    /// un CRI daté par erreur dans le futur reste compté plutôt que de disparaître.
    /// </summary>
    public static StatsFilter LastDays(int days, DateTime? today = null)
    {
        var day = (today ?? DateTime.UtcNow).Date;
        return new StatsFilter { From = day.AddDays(-(days - 1)) };
    }

    /// <summary>Fin effective pour les calculs bornés (courbes) : <see cref="To"/>, sinon demain minuit.</summary>
    public DateTime EffectiveTo(DateTime? today = null) => To ?? (today ?? DateTime.UtcNow).Date.AddDays(1);

    /// <summary>Même périmètre sur la période précédente de même durée, <c>null</c> sans début.</summary>
    public StatsFilter? Previous(DateTime? today = null)
    {
        if (From is not { } from) return null;
        var length = EffectiveTo(today) - from;
        return this with { From = from - length, To = from };
    }

    public IQueryable<CRIForm> Apply(IQueryable<CRIForm> query)
    {
        if (From is { } from)
            query = query.Where(c => c.InterventionDate >= from);
        if (To is { } to)
            query = query.Where(c => c.InterventionDate < to);
        if (TechnicianId is { } technicianId)
            query = query.Where(c => c.TechnicianId == technicianId);
        if (!string.IsNullOrWhiteSpace(Site))
        {
            var site = Site;
            query = query.Where(c => (c.Site != null ? c.Site.NomDuSite : c.ClientSite) == site);
        }
        return query;
    }
}
