using System.Net;
using FluentAssertions;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.Extensions.Logging.Abstractions;
using NovadisApi.Data;
using NovadisApi.Models;
using NovadisApi.Services.Geocoding;

namespace NovadisApi.Tests.Services;

/// <summary>Géocodage des sites (phase 5 de la refonte du dashboard).</summary>
public class SiteGeocodingTests
{
    /// <summary>Réponse réelle de <c>POST data.geopf.fr/geocodage/search/csv</c> (adresses publiques), 2026-09-25.</summary>
    private const string RealResponse =
        "id,adresse,cp,ville,longitude,latitude,result_score,result_score_next,result_label,result_type,result_id,result_banId,result_housenumber,result_name,result_street,result_postcode,result_city,result_context,result_citycode,result_oldcitycode,result_oldcity,result_district,result_status\n" +
        "1,Place de l Hotel de Ville,75004,Paris,2.356161,48.854287,0.79728,0.7230291978609625,Rue de l'Hôtel de Ville 75004 Paris,street,75104_4668,482bd9a7-3540-4858-ae83-2d4f19dd0e0b,,Rue de l'Hôtel de Ville,Rue de l'Hôtel de Ville,75004,Paris,\"75, Paris, Île-de-France\",75104,,,Paris 4e Arrondissement,ok\n" +
        "2,rue inexistante zzz,99999,Nullepart,,,,,,,,,,,,,,,,,,,not-found\n" +
        "3,,69001,Lyon,4.835,45.758,0.9639145454545454,,Lyon,municipality,69123,,,Lyon,,69001,Lyon,\"69, Rhône, Auvergne-Rhône-Alpes\",69123,,,,ok\n";

    [Fact]
    public void ParseResults_ReadsRealServiceResponse()
    {
        var results = GeoplateformeGeocoder.ParseResults(RealResponse).ToDictionary(r => r.Id);
        results["1"].Should().Be(new GeocodingResult("1", 48.854287, 2.356161, 0.79728, "street"));
        results["2"].Should().Be(new GeocodingResult("2", null, null, null, null));
        results["3"].Type.Should().Be("municipality");
        results["3"].Latitude.Should().Be(45.758);
    }

    [Fact]
    public void BuildCsv_EscapesCommasAndQuotes()
    {
        var csv = GeoplateformeGeocoder.BuildCsv([new GeocodingRequest("7", "12, rue \"Haute\"", "69001", null)]);
        csv.Should().Be("id,adresse,cp,ville\n7,\"12, rue \"\"Haute\"\"\",69001,\n");
    }

    [Fact]
    public async Task Geocoder_PostsMultipartCsvToSearchCsv()
    {
        var handler = new RecordingHandler(RealResponse);
        var factory = new SingleClientFactory(new HttpClient(handler) { BaseAddress = new Uri("https://geo.test/geocodage/") });

        var results = await new GeoplateformeGeocoder(factory).GeocodeAsync([new GeocodingRequest("1", "a", "75004", "Paris")]);

        handler.Request!.Method.Should().Be(HttpMethod.Post);
        handler.Request.RequestUri!.ToString().Should().Be("https://geo.test/geocodage/search/csv");
        handler.Body.Should().Contain("name=data").And.Contain("name=columns").And.Contain("name=postcode");
        results.Should().HaveCount(3);
    }

    // ─── Application des résultats ───────────────────────────────────────────

    private static NovadisDbContext NewContext() =>
        new(new DbContextOptionsBuilder<NovadisDbContext>().UseInMemoryDatabase("geo_" + Guid.NewGuid()).Options);

    private sealed class FakeGeocoder(params GeocodingResult[] results) : IGeocoder
    {
        public List<GeocodingRequest> Received { get; } = new();

        public Task<IReadOnlyList<GeocodingResult>> GeocodeAsync(
            IReadOnlyList<GeocodingRequest> requests, CancellationToken ct = default)
        {
            Received.AddRange(requests);
            return Task.FromResult<IReadOnlyList<GeocodingResult>>(results);
        }
    }

    [Fact]
    public async Task GeocodePending_AppliesThreshold_SkipsManualAndDone()
    {
        await using var db = NewContext();
        db.Sites.AddRange(
            new Site { Numero = 1, NomDuSite = "Bon", Adresse = "1 rue A", Ville = "Lyon" },
            new Site { Numero = 2, NomDuSite = "Douteux", Adresse = "?", Ville = "Lyon" },
            new Site { Numero = 3, NomDuSite = "Introuvable", Adresse = "zzz" },
            new Site { Numero = 4, NomDuSite = "Sans adresse" },
            new Site { Numero = 5, NomDuSite = "Manuel", Adresse = "x", CoordonneesManuelles = true, Latitude = 1, Longitude = 2 },
            new Site { Numero = 6, NomDuSite = "Déjà fait", Adresse = "y", GeocodeLe = DateTime.UtcNow, Latitude = 3, Longitude = 4 });
        await db.SaveChangesAsync();
        var geocoder = new FakeGeocoder(
            new GeocodingResult("1", 45.7, 4.8, 0.9, "housenumber"),
            new GeocodingResult("2", 45.0, 4.0, 0.3, "street"),
            new GeocodingResult("3", null, null, null, null));

        var summary = await new SiteGeocodingService(db, geocoder, NullLogger<SiteGeocodingService>.Instance)
            .GeocodePendingAsync();

        summary.Should().Be(new GeocodingSummary(Traites: 4, Localises: 1, AVerifier: 2, SansAdresse: 1));
        geocoder.Received.Select(r => r.Id).Should().BeEquivalentTo("1", "2", "3");   // ni 4, ni 5, ni 6
        var sites = await db.Sites.ToDictionaryAsync(s => s.Numero);
        sites[1].Latitude.Should().Be(45.7);
        sites[1].GeocodagePrecision.Should().Be("housenumber");
        sites[2].Latitude.Should().BeNull("sous le seuil : à vérifier, pas sur la carte");
        sites[2].GeocodageScore.Should().Be(0.3);
        sites[3].GeocodeLe.Should().NotBeNull("tenté : pas de nouvel essai à chaque passe");
        sites[4].GeocodeLe.Should().NotBeNull();
        sites[5].Latitude.Should().Be(1, "coordonnées manuelles jamais écrasées");
        sites[6].Latitude.Should().Be(3);
    }

    [Fact]
    public void ResetIfAddressChanged_OnlyWhenAddressChanges_NeverManual()
    {
        var service = new SiteGeocodingService(NewContext(), new FakeGeocoder(), NullLogger<SiteGeocodingService>.Instance);
        var site = new Site { Adresse = "1 rue A", Ville = "Lyon", Latitude = 1, GeocodeLe = DateTime.UtcNow };

        service.ResetIfAddressChanged(site, "1 rue A", null, "Lyon");
        site.GeocodeLe.Should().NotBeNull();

        service.ResetIfAddressChanged(site, "2 rue B", null, "Lyon");
        site.GeocodeLe.Should().BeNull();
        site.Latitude.Should().BeNull();

        var manual = new Site { Adresse = "a", Latitude = 1, CoordonneesManuelles = true, GeocodeLe = DateTime.UtcNow };
        service.ResetIfAddressChanged(manual, "b", null, null);
        manual.Latitude.Should().Be(1);
    }

    // ─── Endpoint ────────────────────────────────────────────────────────────

    [Fact]
    public async Task GeocodeEndpoint_AdminOnly()
    {
        using var factory = new NovadisWebApplicationFactory();
        using var app = factory.WithWebHostBuilder(b => b.ConfigureTestServices(services =>
        {
            services.RemoveAll<IGeocoder>();
            services.AddScoped<IGeocoder>(_ => new FakeGeocoder());
        }));

        var tech = TestAuthHelper.CreateAuthenticatedClient(app.CreateClient(), Guid.NewGuid(), RoleNames.Technician);
        (await tech.PostAsync("/api/sites/geocode", null)).StatusCode.Should().Be(HttpStatusCode.Forbidden);

        var admin = TestAuthHelper.CreateAuthenticatedClient(app.CreateClient(), Guid.NewGuid(), RoleNames.Admin);
        (await admin.PostAsync("/api/sites/geocode", null)).StatusCode.Should().Be(HttpStatusCode.OK);
    }

    private sealed class RecordingHandler(string response) : HttpMessageHandler
    {
        public HttpRequestMessage? Request { get; private set; }
        public string Body { get; private set; } = "";

        protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken ct)
        {
            Request = request;
            Body = await request.Content!.ReadAsStringAsync(ct);
            return new HttpResponseMessage(HttpStatusCode.OK) { Content = new StringContent(response) };
        }
    }

    private sealed class SingleClientFactory(HttpClient client) : IHttpClientFactory
    {
        public HttpClient CreateClient(string name) => client;
    }
}
