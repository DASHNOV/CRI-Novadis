using Microsoft.EntityFrameworkCore;
using NovadisApi.Data;
using NovadisApi.Models;

namespace NovadisApi.Services.Geocoding;

/// <summary>Bilan d'une passe de géocodage.</summary>
public sealed record GeocodingSummary(int Traites, int Localises, int AVerifier, int SansAdresse);

public interface ISiteGeocodingService
{
    /// <summary>
    /// Géocode les sites à traiter (<see cref="Site.GeocodeLe"/> nul) ou tous avec
    /// <paramref name="force"/>. Les coordonnées manuelles ne sont jamais touchées.
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

        await _context.SaveChangesAsync(ct);
        var summary = new GeocodingSummary(sites.Count, located, toCheck, withoutAddress.Count);
        _logger.LogInformation("Géocodage des sites : {Summary}", summary);
        return summary;
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
