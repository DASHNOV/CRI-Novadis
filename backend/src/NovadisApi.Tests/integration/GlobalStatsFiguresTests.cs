using System.Net;
using System.Text.Json;
using FluentAssertions;
using Microsoft.Extensions.DependencyInjection;
using NovadisApi.Data;
using NovadisApi.Models;
using NovadisApi.Services.Stats;

namespace NovadisApi.Tests.Integration;

/// <summary>
/// Chiffres des tableaux de bord figés sur un jeu connu, calculés à la main.
/// Filet de toute réécriture des agrégations (en SQL notamment) : les mêmes chiffres
/// doivent sortir, y compris sur les cas limites (durée nulle ou à 0, catégorie vide,
/// site non renseigné).
///
/// Jeu (tous en mars 2026, sans entité Site : le nom du site vient de ClientSite) :
///   #  tech type    catégorie     ville  site   durée statut              signé récurrence
///   1  T1   Service Maintenance   Lyon   SiteA   60   resolu              oui
///   2  T1   Service Maintenance   Lyon   SiteA  120   nonResolu           non   oui
///   3  T1   Project Installation  Paris  SiteB  null  partiellementResolu oui
///   4  T2   Service Depannage     Lyon   SiteA   30   resolu              oui
///   5  T2   Project Installation  Paris  SiteB    0   enAttente           non   oui
///   6  T2   Service Maintenance   —      —       90   resolu              oui
/// </summary>
public class GlobalStatsFiguresTests : IClassFixture<NovadisWebApplicationFactory>
{
    private readonly NovadisWebApplicationFactory _factory;
    private readonly Guid _t1 = Guid.NewGuid();
    private readonly Guid _t2 = Guid.NewGuid();

    public GlobalStatsFiguresTests(NovadisWebApplicationFactory factory)
    {
        _factory = factory;
    }

    private async Task SeedAsync()
    {
        await TestDataSeeder.SeedUserAsync(_factory, _t1, $"t1-{_t1:N}@novadis.fr");
        await TestDataSeeder.SeedUserAsync(_factory, _t2, $"t2-{_t2:N}@novadis.fr");

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<NovadisDbContext>();
        void Add(Guid tech, string type, string cat, string? ville, string? site, int? duree,
            string status, bool signe, bool recurrence) =>
            db.CRIForms.Add(new CRIForm
            {
                Id = Guid.NewGuid(), TechnicianId = tech, InterventionType = type, Category = cat,
                InterventionDate = new DateTime(2026, 3, 10, 8, 0, 0, DateTimeKind.Utc),
                ClientName = $"Client {site ?? "?"}", ClientSite = site, Ville = ville, DureeMinutes = duree,
                ResolutionStatus = status, AdditionalInterventionRequired = recurrence,
                ClientSignature = signe ? "sig" : null, Data = "{}", Status = "Submitted",
            });

        Add(_t1, "Service", "Maintenance", "Lyon", "SiteA", 60, "resolu", true, false);
        Add(_t1, "Service", "Maintenance", "Lyon", "SiteA", 120, "nonResolu", false, true);
        Add(_t1, "Project", "Installation", "Paris", "SiteB", null, "partiellementResolu", true, false);
        Add(_t2, "Service", "Depannage", "Lyon", "SiteA", 30, "resolu", true, false);
        Add(_t2, "Project", "Installation", "Paris", "SiteB", 0, "enAttente", false, true);
        Add(_t2, "Service", "Maintenance", null, null, 90, "resolu", true, false);
        await db.SaveChangesAsync();
    }

    // Un seul test : les statistiques portent sur toute la base, un second jeu les fausserait.
    [Fact]
    public async Task Figures_MatchHandComputedValues()
    {
        await SeedAsync();
        using var scope = _factory.Services.CreateScope();
        var stats = scope.ServiceProvider.GetRequiredService<IGlobalStatsService>();

        // ── Vue globale ─────────────────────────────────────────────────────
        var global = await stats.GetGlobalStatsAsync(null);
        global.TotalCeMois.Should().Be(6);
        global.TotalSignes.Should().Be(4);
        global.TotalEnAttente.Should().Be(2);
        global.TechniciensActifs.Should().Be(2);
        global.DureeMoyenneMinutes.Should().Be(75);          // (60+120+30+90)/4 : null et 0 exclus
        global.TotalProjets.Should().Be(2);
        global.TotalServices.Should().Be(4);
        global.TotalResolu.Should().Be(3);
        global.TotalNonResolu.Should().Be(2);                // nonResolu + partiellementResolu
        global.TotalRecurrenceRequise.Should().Be(2);
        global.RepartitionParVille.Should().BeEquivalentTo(new Dictionary<string, int> { ["Lyon"] = 3, ["Paris"] = 2 });

        // ── Par site ────────────────────────────────────────────────────────
        var bySite = await stats.GetStatsBySiteAsync(null);
        bySite.Select(s => s.SiteNom).Should().Equal("SiteA", "SiteB");   // site vide exclu, tri décroissant
        var siteA = bySite[0];
        siteA.TotalInterventions.Should().Be(3);
        siteA.DureeMoyenneMinutes.Should().Be(70);
        siteA.TotalResolu.Should().Be(2);
        siteA.TotalNonResolu.Should().Be(1);
        siteA.TauxRecurrence.Should().Be(33.3);
        siteA.TopCategorie.Should().Be("Maintenance");
        siteA.TopCategorieCount.Should().Be(2);
        siteA.TechniciensDistincts.Should().Be(2);
        var siteB = bySite[1];
        siteB.TotalInterventions.Should().Be(2);
        siteB.DureeMoyenneMinutes.Should().BeNull();         // null et 0 seulement
        siteB.TauxRecurrence.Should().Be(50);
        siteB.TotalProjets.Should().Be(2);

        // ── Par technicien ──────────────────────────────────────────────────
        var byTech = (await stats.GetStatsByTechnicianAsync(null)).ToDictionary(t => t.Id);
        var t1 = byTech[_t1];
        t1.TotalInterventions.Should().Be(3);
        t1.DureeMoyenneMinutes.Should().Be(90);
        t1.TotalHeures.Should().Be(3);
        t1.TotalResolu.Should().Be(1);
        t1.TotalNonResolu.Should().Be(2);
        t1.SitesDistincts.Should().Be(2);
        t1.RepartitionParType.Should().BeEquivalentTo(new Dictionary<string, int>
            { ["Service"] = 2, ["Projet"] = 1, ["Maintenance"] = 2, ["Installation"] = 1 });
        var t2 = byTech[_t2];
        t2.TotalInterventions.Should().Be(3);
        t2.DureeMoyenneMinutes.Should().Be(60);
        t2.TotalHeures.Should().Be(2);
        t2.SitesDistincts.Should().Be(2);                    // CRI sans site non compté

        // ── Répartitions ────────────────────────────────────────────────────
        var distribution = await stats.GetDistributionStatsAsync(null);
        distribution.RepartitionParCategorie.Should().BeEquivalentTo(new Dictionary<string, int>
            { ["Maintenance"] = 3, ["Installation"] = 2, ["Depannage"] = 1 });
        distribution.EvolutionMensuelle.Should().ContainSingle()
            .Which.TotalInterventions.Should().Be(6);
        distribution.CategorieParSite.Select(e => (e.Ligne, e.Colonne, e.Valeur)).Should().BeEquivalentTo(new[]
            { ("SiteA", "Maintenance", 2), ("SiteB", "Installation", 2), ("SiteA", "Depannage", 1) });
    }
}

/// <summary>Liste « Tous les CRI » allégée (étape 4.1). Classe à part : base distincte du jeu figé.</summary>
public class GlobalCrisListTests : IClassFixture<NovadisWebApplicationFactory>
{
    private readonly NovadisWebApplicationFactory _factory;

    public GlobalCrisListTests(NovadisWebApplicationFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task GlobalCrisList_OmitsDataAndTechnicianSignature_KeepsClientSignature()
    {
        var techId = Guid.NewGuid();
        await TestDataSeeder.SeedUserAsync(_factory, techId, $"list-{techId:N}@novadis.fr");
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<NovadisDbContext>();
            db.CRIForms.Add(new CRIForm
            {
                Id = Guid.NewGuid(), TechnicianId = techId, InterventionType = "Service", Category = "Maintenance",
                InterventionDate = DateTime.UtcNow, ClientName = "Client liste",
                Data = "{\"lourd\":true}", TechnicianSignature = "sigT", ClientSignature = "sigC",
            });
            await db.SaveChangesAsync();
        }

        var client = TestAuthHelper.CreateAuthenticatedClient(_factory.CreateClient(), Guid.NewGuid(), RoleNames.Admin);
        var response = await client.GetAsync($"/api/global/cris?technicienId={techId}");
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var cri = JsonDocument.Parse(await response.Content.ReadAsStringAsync())
            .RootElement.GetProperty("data").EnumerateArray().Single();
        cri.TryGetProperty("data", out _).Should().BeFalse();
        cri.TryGetProperty("technicianSignature", out _).Should().BeFalse();
        cri.GetProperty("clientSignature").GetString().Should().Be("sigC");   // statut « signé », APK installés
    }
}
