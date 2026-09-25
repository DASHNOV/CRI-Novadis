using FluentAssertions;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using NovadisApi.Data;
using NovadisApi.Models;
using NovadisApi.Services.Geocoding;
using NovadisApi.Services.Stats;

namespace NovadisApi.Tests.Integration;

/// <summary>
/// Retours sur le dashboard (2026-09-25) : « Test » et « test » comptaient comme deux
/// sites ; les sites saisis librement n'apparaissaient jamais sur la carte.
///   Test  (Lyon)   ×2, « test  » ×1  → un seul site « Test »
///   Libre (Nantes) ×1               → placé via l'adresse du CRI
/// </summary>
public class SiteGroupingTests : IClassFixture<NovadisWebApplicationFactory>, IAsyncLifetime
{
    private readonly NovadisWebApplicationFactory _factory;
    private static readonly Guid Tech = Guid.NewGuid();

    public SiteGroupingTests(NovadisWebApplicationFactory factory)
    {
        _factory = factory;
    }

    private sealed class FakeGeocoder : IGeocoder
    {
        public int Calls { get; private set; }

        public Task<IReadOnlyList<GeocodingResult>> GeocodeAsync(
            IReadOnlyList<GeocodingRequest> requests, CancellationToken ct = default)
        {
            Calls++;
            return Task.FromResult<IReadOnlyList<GeocodingResult>>(requests
                .Select(r => r.Ville == "nantes"
                    ? new GeocodingResult(r.Id, 47.21, -1.55, 0.9, "housenumber")
                    : new GeocodingResult(r.Id, 45.76, 4.83, 0.3, "street"))   // sous le seuil
                .ToList());
        }
    }

    public async Task InitializeAsync()
    {
        using (var check = _factory.Services.CreateScope())
        {
            if (check.ServiceProvider.GetRequiredService<NovadisDbContext>().Users.Any(u => u.Id == Tech))
                return;
        }
        await TestDataSeeder.SeedUserAsync(_factory, Tech, $"grouping-{Tech:N}@novadis.fr");

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<NovadisDbContext>();
        void Add(string site, string ville, string? adresse = null) => db.CRIForms.Add(new CRIForm
        {
            Id = Guid.NewGuid(), TechnicianId = Tech, InterventionType = "Service", Category = "Maintenance",
            InterventionDate = DateTime.UtcNow.Date, ClientName = "Client", ClientSite = site,
            ClientAddress = adresse, Ville = ville, Data = "{}", Status = "Submitted",
        });
        Add("Test", "Lyon");
        Add("Test", "Lyon");
        Add("test  ", "Lyon");
        Add("Libre", "Nantes", "3 rue Kervégan");
        await db.SaveChangesAsync();
    }

    public Task DisposeAsync() => Task.CompletedTask;

    private IServiceScope Scope() => _factory.Services.CreateScope();

    [Fact]
    public async Task SitesDifferingOnlyByCaseOrSpaces_AreOneSite()
    {
        using var scope = Scope();
        var stats = scope.ServiceProvider.GetRequiredService<IGlobalStatsService>();

        var sites = await stats.GetStatsBySiteAsync(StatsFilter.All);
        sites.Select(s => (s.SiteNom, s.TotalInterventions))
            .Should().BeEquivalentTo(new[] { ("Test", 3), ("Libre", 1) });

        // Page site : le filtre suit la même règle.
        (await stats.GetGlobalStatsAsync(StatsFilter.All with { Site = " TEST" }))
            .TotalInterventions.Should().Be(3);

        var byTech = (await stats.GetStatsByTechnicianAsync(StatsFilter.All)).Single(t => t.Id == Tech);
        byTech.SitesDistincts.Should().Be(2);
    }

    [Fact]
    public async Task FreeTextSites_ArePlacedFromTheCriAddress()
    {
        using var scope = Scope();
        var db = scope.ServiceProvider.GetRequiredService<NovadisDbContext>();
        var geocoder = new FakeGeocoder();
        var service = new SiteGeocodingService(db, geocoder, NullLogger<SiteGeocodingService>.Instance);

        var summary = await service.GeocodePendingAsync();
        summary.AdressesCriTraitees.Should().Be(2);        // Lyon (sans adresse) et Nantes
        summary.AdressesCriLocalisees.Should().Be(1);      // Lyon sous le seuil

        // Deuxième passe : tout est en cache, aucun appel.
        var callsBefore = geocoder.Calls;
        (await service.GeocodePendingAsync()).AdressesCriTraitees.Should().Be(0);
        geocoder.Calls.Should().Be(callsBefore);

        var stats = scope.ServiceProvider.GetRequiredService<IGlobalStatsService>();
        var sites = (await stats.GetStatsBySiteAsync(StatsFilter.All)).ToDictionary(s => s.SiteNom);
        sites["Libre"].Latitude.Should().Be(47.21);
        sites["Libre"].LocalisationSource.Should().Be("cri");
        sites["Test"].Latitude.Should().BeNull("score 0,3 : à vérifier, pas sur la carte");
        sites["Test"].LocalisationSource.Should().BeNull();
    }

    [Fact]
    public void AddressKey_NormalizesAndSkipsEmpty()
    {
        AddressKey.From(" 3  Rue Kervégan ", "44000", "Nantes").Should().Be("3 rue kervégan|44000|nantes");
        AddressKey.From(null, " ", "").Should().BeNull();
        AddressKey.Split("3 rue x|44000|nantes").Should().Be(("3 rue x", "44000", "nantes"));
    }
}
