using System.Net;
using System.Text.Json;
using FluentAssertions;
using Microsoft.Extensions.DependencyInjection;
using NovadisApi.Data;
using NovadisApi.Models;
using NovadisApi.Models.DTOs;
using NovadisApi.Services.Stats;

namespace NovadisApi.Tests.Integration;

/// <summary>
/// Endpoints du dashboard (phase 2 de la refonte) : filtre commun (période, plage,
/// technicien, site), courbe d'évolution, interventions récentes, périmètre personnel.
///
/// Jeu (J = aujourd'hui, minuit UTC) :
///   #  tech  date   site   statut
///   1  A     J      SiteA  resolu
///   2  A     J-29   SiteA  nonResolu     ← premier jour des 30 derniers jours
///   3  A     J-30   SiteB  resolu        ← hors 30 jours
///   4  B     J-2    SiteB  resolu
///   5  B     J-200  SiteA  resolu
/// </summary>
public class DashboardEndpointsTests : IClassFixture<NovadisWebApplicationFactory>, IAsyncLifetime
{
    private readonly NovadisWebApplicationFactory _factory;
    // Statiques : xUnit recrée la classe à chaque test, la base (fixture) est partagée.
    private static readonly Guid _techA = Guid.NewGuid();
    private static readonly Guid _techB = Guid.NewGuid();
    private static readonly DateTime Today = DateTime.UtcNow.Date;

    public DashboardEndpointsTests(NovadisWebApplicationFactory factory)
    {
        _factory = factory;
    }

    public async Task InitializeAsync()
    {
        using (var check = _factory.Services.CreateScope())
        {
            if (check.ServiceProvider.GetRequiredService<NovadisDbContext>().Users.Any(u => u.Id == _techA))
                return;
        }

        await TestDataSeeder.SeedUserAsync(_factory, _techA, $"a-{_techA:N}@novadis.fr");
        await TestDataSeeder.SeedUserAsync(_factory, _techB, $"b-{_techB:N}@novadis.fr");

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<NovadisDbContext>();
        void Add(Guid tech, int daysAgo, string site, string status) => db.CRIForms.Add(new CRIForm
        {
            Id = Guid.NewGuid(), TechnicianId = tech, InterventionType = "Service", Category = "Maintenance",
            InterventionDate = Today.AddDays(-daysAgo), ClientName = "Client", ClientSite = site,
            ResolutionStatus = status, Data = "{}", Status = "Submitted",
            CreatedAt = DateTime.UtcNow.AddMinutes(-daysAgo),
        });
        Add(_techA, 0, "SiteA", "resolu");
        Add(_techA, 29, "SiteA", "nonResolu");
        Add(_techA, 30, "SiteB", "resolu");
        Add(_techB, 2, "SiteB", "resolu");
        Add(_techB, 200, "SiteA", "resolu");
        await db.SaveChangesAsync();
    }

    public Task DisposeAsync() => Task.CompletedTask;

    private IGlobalStatsService Stats() =>
        _factory.Services.CreateScope().ServiceProvider.GetRequiredService<IGlobalStatsService>();

    private HttpClient As(Guid userId, string role) =>
        TestAuthHelper.CreateAuthenticatedClient(_factory.CreateClient(), userId, role);

    private static async Task<JsonElement> DataOf(HttpResponseMessage response)
    {
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        return JsonDocument.Parse(await response.Content.ReadAsStringAsync()).RootElement.GetProperty("data");
    }

    // ─── Filtre ──────────────────────────────────────────────────────────────

    [Fact]
    public async Task LastDays_IncludesFirstDayAtMidnight_ExcludesTheDayBefore()
    {
        var stats = await Stats().GetGlobalStatsAsync(StatsFilter.LastDays(30));
        stats.TotalInterventions.Should().Be(3);   // #1, #2, #4
    }

    [Fact]
    public async Task TechnicianAndSiteFilters_Combine()
    {
        var filter = StatsFilter.All with { TechnicianId = _techA, Site = "SiteA" };
        (await Stats().GetGlobalStatsAsync(filter)).TotalInterventions.Should().Be(2);
    }

    [Fact]
    public void Previous_IsContiguousAndOfSameLength()
    {
        var today = new DateTime(2026, 9, 25);
        var previous = StatsFilter.LastDays(7, today).Previous(today)!;
        previous.From.Should().Be(new DateTime(2026, 9, 12));
        previous.To.Should().Be(new DateTime(2026, 9, 19));
    }

    [Fact]
    public void Query_FromTo_ToIsInclusive()
    {
        var query = new StatsQuery { From = new DateOnly(2026, 9, 1), To = new DateOnly(2026, 9, 30), Period = 7 };
        query.TryToFilter(out var filter, out _).Should().BeTrue();
        filter.From.Should().Be(new DateTime(2026, 9, 1));
        filter.To.Should().Be(new DateTime(2026, 10, 1));   // from/to priment sur period
    }

    [Fact]
    public async Task Query_ToBeforeFrom_Is400()
    {
        var response = await As(Guid.NewGuid(), RoleNames.Admin)
            .GetAsync("/api/global/stats?from=2026-09-10&to=2026-09-01");
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    // ─── Évolution ───────────────────────────────────────────────────────────

    [Fact]
    public async Task Evolution_30Days_OnePointPerDay_FirstDayCounted()
    {
        var evolution = await Stats().GetEvolutionAsync(StatsFilter.LastDays(30));
        evolution.Granularity.Should().Be("day");
        evolution.Points.Should().HaveCount(30);
        evolution.Points.First().Debut.Should().Be(Today.AddDays(-29));
        evolution.Points.First().Total.Should().Be(1);
        evolution.Points.Last().Debut.Should().Be(Today);
        evolution.Points.Sum(p => p.Total).Should().Be(3);
        evolution.Points.Sum(p => p.Resolu).Should().Be(2);
    }

    [Fact]
    public async Task Evolution_OneDay_ShowsAWeek()
    {
        var evolution = await Stats().GetEvolutionAsync(StatsFilter.LastDays(1));
        evolution.Points.Should().HaveCount(7);
    }

    [Theory]
    [InlineData(60, "week")]
    [InlineData(365, "month")]
    public async Task Evolution_Granularity_FollowsSpan(int days, string expected)
    {
        var evolution = await Stats().GetEvolutionAsync(StatsFilter.LastDays(days));
        evolution.Granularity.Should().Be(expected);
        evolution.Points.Sum(p => p.Total).Should().Be(days >= 201 ? 5 : 4);
    }

    [Fact]
    public async Task Evolution_AllTime_StartsAtFirstIntervention()
    {
        var evolution = await Stats().GetEvolutionAsync(StatsFilter.All with { TechnicianId = _techB });
        evolution.Granularity.Should().Be("month");
        evolution.Points.Sum(p => p.Total).Should().Be(2);
    }

    // ─── Récentes ────────────────────────────────────────────────────────────

    [Fact]
    public async Task Recent_NewestFirst_Limited()
    {
        var recent = await Stats().GetRecentInterventionsAsync(StatsFilter.All, 2);
        recent.Select(r => r.InterventionDate).Should().Equal(Today, Today.AddDays(-2));
        recent[0].TechnicienNom.Should().Be("Test User");
        recent[0].SiteNom.Should().Be("SiteA");
    }

    // ─── Périmètre personnel ─────────────────────────────────────────────────

    [Fact]
    public async Task Personal_IgnoresTechnicienIdParameter()
    {
        var data = await DataOf(await As(_techA, RoleNames.Technician)
            .GetAsync($"/api/personal/dashboard/stats?technicienId={_techB}"));
        data.GetProperty("totalInterventions").GetInt32().Should().Be(3);
    }

    [Fact]
    public async Task Personal_EndpointsAnswerWithOwnData()
    {
        var client = As(_techB, RoleNames.Technician);
        (await DataOf(await client.GetAsync("/api/personal/dashboard/recent?limit=5")))
            .GetArrayLength().Should().Be(2);
        (await DataOf(await client.GetAsync("/api/personal/dashboard/by-site?period=30")))
            .EnumerateArray().Single().GetProperty("siteNom").GetString().Should().Be("SiteB");
        (await DataOf(await client.GetAsync("/api/personal/dashboard/evolution?period=7")))
            .GetProperty("points").GetArrayLength().Should().Be(7);
    }

    // ─── Droits ──────────────────────────────────────────────────────────────

    [Fact]
    public async Task GlobalDashboardEndpoints_TechnicianDenied()
    {
        var tech = As(_techA, RoleNames.Technician);
        (await tech.GetAsync("/api/global/stats/evolution")).StatusCode.Should().Be(HttpStatusCode.Forbidden);
        (await tech.GetAsync("/api/global/stats/recent")).StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    [Fact]
    public async Task PersonalDashboard_SupervisorDenied()
    {
        (await As(Guid.NewGuid(), RoleNames.Supervisor).GetAsync("/api/personal/dashboard/stats"))
            .StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }
}
