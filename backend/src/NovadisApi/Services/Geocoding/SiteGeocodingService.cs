using Microsoft.EntityFrameworkCore;
using NovadisApi.Data;
using NovadisApi.Models;

namespace NovadisApi.Services.Geocoding;

/// <summary>
/// Bilan d'une passe de géocodage : sites du référentiel, puis adresses des CRI
/// hors référentiel (repli pour la carte).
/// </summary>
public sealed record GeocodingSummary(
    int Traites, int Localises, int AVerifier, int SansAdresse,
    int AdressesCriTraitees = 0, int AdressesCriLocalisees = 0);

public interface ISiteGeocodingService
{
    /// <summary>
    /// Géocode les sites à traiter (<see cref="Site.GeocodeLe"/> nul) ou tous avec
    /// <paramref name="force"/>. Les coordonnées manuelles ne sont jamais touchées.
    /// Géocode aussi les adresses des CRI sans site du référentiel absentes du cache.
    /// </summary>
    Task<GeocodingSummary> GeocodePendingAsync(bool force = false, CancellationToken ct = default);

    /// <summary>Marque le site à regéocoder si son adresse a changé (hors coordonnées manuelles).</summary>
    void ResetIfAddressChanged(Site site, string? adresse, string? codePostal, string? ville);
}

public sealed class SiteGeocodingService : ISiteGeocodingService
{
    /// <summary>
    /// Sous ce score, le résultat n'est pas placé sur la carte (« à vérifier ») :
    /// mieux vaut un site absent qu'un site au mauvais endroit.
    /// </summary>
    public const double MinScore = 0.5;

    private readonly NovadisDbContext _context;
    private readonly IGeocoder _geocoder;
    private readonly ILogger<SiteGeocodingService> _logger;

    public SiteGeocodingService(NovadisDbContext context, IGeocoder geocoder, ILogger<SiteGeocodingService> logger)
    {
        _context = context;
        _geocoder = geocoder;
        _logger = logger;
    }

    public async Task<GeocodingSummary> GeocodePendingAsync(bool force = false, CancellationToken ct = default)
    {
        var sites = await _context.Sites
            .Where(s => !s.CoordonneesManuelles && (force || s.GeocodeLe == null))
            .ToListAsync(ct);

        var now = DateTime.UtcNow;
        var withoutAddress = sites
            .Where(s => string.IsNullOrWhiteSpace(s.Adresse) && string.IsNullOrWhiteSpace(s.Ville)
                && string.IsNullOrWhiteSpace(s.CodePostal))
            .ToList();
        foreach (var site in withoutAddress)
        {
            Clear(site);
            site.GeocodeLe = now;   // rien à chercher : ne pas retenter à chaque passe
        }

        var toGeocode = sites.Except(withoutAddress).ToList();
        var results = toGeocode.Count == 0
            ? new Dictionary<string, GeocodingResult>()
            : (await _geocoder.GeocodeAsync(
                    toGeocode.Select(s => new GeocodingRequest(
                        s.Numero.ToString(), s.Adresse, s.CodePostal, s.Ville)).ToList(), ct))
                .ToDictionary(r => r.Id);

        int located = 0, toCheck = 0;
        foreach (var site in toGeocode)
        {
            results.TryGetValue(site.Numero.ToString(), out var result);
            site.GeocodeLe = now;
            site.GeocodageScore = result?.Score;
            site.GeocodagePrecision = result?.Type;
            if (result is { Latitude: { } lat, Longitude: { } lon, Score: >= MinScore })
            {
                site.Latitude = lat;
                site.Longitude = lon;
                located++;
            }
            else
            {
                site.Latitude = null;
                site.Longitude = null;
                toCheck++;
            }
        }

        var (addressesDone, addressesLocated) = await GeocodeCriAddressesAsync(force, now, ct);

        await _context.SaveChangesAsync(ct);
        var summary = new GeocodingSummary(
            sites.Count, located, toCheck, withoutAddress.Count, addressesDone, addressesLocated);
        _logger.LogInformation("Géocodage des sites : {Summary}", summary);
        return summary;
    }

    /// <summary>
    /// Adresses des CRI hors référentiel (saisie libre du site) : une entrée de cache
    /// par adresse distincte, pour que la carte puisse les placer sans appel externe.
    /// </summary>
    private async Task<(int Done, int Located)> GeocodeCriAddressesAsync(
        bool force, DateTime now, CancellationToken ct)
    {
        var rows = await _context.CRIForms
            .Where(c => c.SiteID == null && c.ClientSite != null && c.ClientSite != "")
            .Select(c => new { c.ClientAddress, c.CodePostal, c.Ville })
            .Distinct()
            .ToListAsync(ct);
        var keys = rows
            .Select(r => AddressKey.From(r.ClientAddress, r.CodePostal, r.Ville))
            .OfType<string>()
            .Distinct()
            .ToList();
        if (keys.Count == 0) return (0, 0);

        var cached = await _context.AdressesGeocodees
            .Where(a => keys.Contains(a.Cle))
            .ToDictionaryAsync(a => a.Cle, ct);
        var toGeocode = force ? keys : keys.Where(k => !cached.ContainsKey(k)).ToList();
        if (toGeocode.Count == 0) return (0, 0);

        var results = (await _geocoder.GeocodeAsync(
                toGeocode.Select(k =>
                {
                    var (adresse, cp, ville) = AddressKey.Split(k);
                    return new GeocodingRequest(k, adresse, cp, ville);
                }).ToList(), ct))
            .ToDictionary(r => r.Id);

        var located = 0;
        foreach (var key in toGeocode)
        {
            results.TryGetValue(key, out var result);
            var ok = result is { Latitude: not null, Longitude: not null, Score: >= MinScore };
            if (ok) located++;
            if (!cached.TryGetValue(key, out var entry))
            {
                entry = new AdresseGeocodee { Cle = key };
                _context.AdressesGeocodees.Add(entry);
            }
            entry.Latitude = ok ? result!.Latitude : null;
            entry.Longitude = ok ? result!.Longitude : null;
            entry.Score = result?.Score;
            entry.Precision = result?.Type;
            entry.GeocodeLe = now;
        }
        return (toGeocode.Count, located);
    }

    public void ResetIfAddressChanged(Site site, string? adresse, string? codePostal, string? ville)
    {
        if (site.CoordonneesManuelles) return;
        if (site.Adresse == adresse && site.CodePostal == codePostal && site.Ville == ville) return;
        Clear(site);
        site.GeocodeLe = null;
    }

    private static void Clear(Site site)
    {
        site.Latitude = null;
        site.Longitude = null;
        site.GeocodageScore = null;
        site.GeocodagePrecision = null;
    }
}
