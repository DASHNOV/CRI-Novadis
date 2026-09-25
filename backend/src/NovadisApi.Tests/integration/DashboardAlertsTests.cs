using System.Net;
using System.Text.Json;
using FluentAssertions;
using Microsoft.Extensions.DependencyInjection;
using NovadisApi.Data;
using NovadisApi.Models;
using NovadisApi.Services.Stats;

namespace NovadisApi.Tests.Integration;

/// <summary>
/// Alertes du dashboard (phase 4). Jeu (J = aujourd'hui) :
///   SiteR   4 CRI dont 2 avec retour  → 50 %  : signalé
///   SiteS   1 CRI avec retour         → 100 % mais &lt; 3 CRI : bruit, non signalé
///   SiteOK  5 CRI dont 1 avec retour  → 20 %  : seuil non dépassé
///   Services non résolus : J-20 (nonResolu), J-15 (escaladeNiveau2), J-5 (trop récent)
///   Projet « enCours » à J-30 : un projet n'est pas un service non résolu
/// </summary>
public class DashboardAlertsTests : IClassFixture<NovadisWebApplicationFactory>, IAsyncLifetime
{
    private readonly NovadisWebApplicationFactory _factory;
    private static readonly Guid Tech = Guid.NewGuid();
    private static readonly DateTime Today = DateTime.UtcNow.Date;

    public DashboardAlertsTests(NovadisWebApplicationFactory factory)
    {
        _factory = factory;
    }

    public async Task InitializeAsync()
    {
        using (var check = _factory.Services.CreateScope())
        {
            if (check.ServiceProvider.GetRequiredService<NovadisDbContext>().Users.Any(u => u.Id == Tech))
                return;
        }
        await TestDataSeeder.SeedUserAsync(_factory, Tech, $"alerts-{Tech:N}@novadis.fr");

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<NovadisDbContext>();
        void Add(string site, int daysAgo, bool recurrence = false, string status = "resolu",
            string type = "Service", string? projectStatus = null) => db.CRIForms.Add(new CRIForm
        {
            Id = Guid.NewGuid(), TechnicianId = Tech, InterventionType = type, Category = "Maintenance",
            InterventionDate = Today.AddDays(-daysAgo), ClientName = "Client", ClientSite = site,
            ResolutionStatus = type == "Service" ? status : null, ProjectStatus = projectStatus,
            AdditionalInterventionRequired = recurrence, Data = "{}", Status = "Submitted",
        });

        Add("SiteR", 1, recurrence: true);
        Add("SiteR", 2, recurrence: true);
        Add("SiteR", 3);
        Add("SiteR", 4);
        Add("SiteS", 1, recurrence: true);
        Add("SiteOK", 1, recurrence: true);
        for (var i = 2; i <= 5; i++) Add("SiteOK", i);
        Add("SiteU", 20, status: "nonResolu");
        Add("SiteU", 15, status: "escaladeNiveau2");
        Add("SiteU", 5, status: "nonResolu");
        Add("SiteP", 30, type: "Project", projectStatus: "enCours");
        await db.SaveChangesAsync();
    }

    public Task DisposeAsync() => Task.CompletedTask;

    private static IGlobalStatsService Stats(NovadisWebApplicationFactory f) =>
        f.Services.CreateScope().ServiceProvider.GetRequiredService<IGlobalStatsService>();

    [Fact]
    public async Task RecurrenceAlert_AboveThreshold_WithEnoughInterventions()
    {
        var alerts = await Stats(_factory).GetAlertsAsync(StatsFilter.LastDays(30), 14);
        alerts.SitesRecurrence.Select(s => s.SiteNom).Should().Equal("SiteR");
        alerts.SitesRecurrence[0].TauxRecurrence.Should().Be(50);
    }

    [Fact]
    public async Task UnresolvedServices_OlderThanStaleDays_OldestFirst()
    {
        var alerts = await Stats(_factory).GetAlertsAsync(StatsFilter.LastDays(90), 14);
        alerts.CriNonResolusTotal.Should().Be(2);
        alerts.CriNonResolus.Select(c => c.InterventionDate).Should().Equal(Today.AddDays(-20), Today.AddDays(-15));

        (await Stats(_factory).GetAlertsAsync(StatsFilter.LastDays(90), 16)).CriNonResolusTotal.Should().Be(1);
    }

    [Fact]
    public async Task Escalations_OnPeriod()
    {
        (await Stats(_factory).GetAlertsAsync(StatsFilter.LastDays(30), 14)).EscaladesTotal.Should().Be(1);
        (await Stats(_factory).GetAlertsAsync(StatsFilter.LastDays(7), 14)).EscaladesTotal.Should().Be(0);
    }

    [Fact]
    public async Task Endpoints_GlobalAndPersonal()
    {
        var admin = TestAuthHelper.CreateAuthenticatedClient(_factory.CreateClient(), Guid.NewGuid(), RoleNames.Admin);
        var response = await admin.GetAsync("/api/global/stats/alerts?period=30&staleDays=14");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var data = JsonDocument.Parse(await response.Content.ReadAsStringAsync()).RootElement.GetProperty("data");
        data.GetProperty("joursSansResolution").GetInt32().Should().Be(14);

        var tech = TestAuthHelper.CreateAuthenticatedClient(_factory.CreateClient(), Tech, RoleNames.Technician);
        (await tech.GetAsync("/api/personal/dashboard/alerts?period=30")).StatusCode.Should().Be(HttpStatusCode.OK);
        (await tech.GetAsync("/api/global/stats/alerts")).StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }
}
