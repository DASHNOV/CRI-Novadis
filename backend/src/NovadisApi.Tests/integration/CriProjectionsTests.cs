using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using NovadisApi.Data;
using NovadisApi.Models;
using NovadisApi.Services.Export;

namespace NovadisApi.Tests.Integration;

/// <summary>
/// Étape 4.1 : la projection allégée des exports recopie toutes les colonnes sauf
/// Data et les signatures. Un champ oublié arriverait vide dans l'XLSX sans erreur.
/// </summary>
public class CriProjectionsTests : IClassFixture<NovadisWebApplicationFactory>
{
    private readonly NovadisWebApplicationFactory _factory;

    public CriProjectionsTests(NovadisWebApplicationFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task WithoutHeavyColumns_CopiesEveryOtherColumn_AndLoadsNavigations()
    {
        var techId = Guid.NewGuid();
        await TestDataSeeder.SeedUserAsync(_factory, techId, $"proj-{techId:N}@novadis.fr");

        var cri = new CRIForm
        {
            Id = Guid.NewGuid(),
            TechnicianId = techId,
            InterventionType = "Project",
            Category = "Installation",
            InterventionDate = new DateTime(2026, 3, 10, 8, 0, 0, DateTimeKind.Utc),
            ClientName = "Client", ClientAddress = "1 rue", ClientSite = "Site", ClientPhone = "0102",
            ClientEmail = "c@x.fr", WorkDescription = "travail", MaterialsUsed = "câble",
            Duration = 1.5m, Status = "Submitted",
            Data = "{\"lourd\":true}", TechnicianSignature = "sigT", ClientSignature = "sigC",
            CreatedAt = new DateTime(2026, 3, 10, 9, 0, 0, DateTimeKind.Utc),
            UpdatedAt = new DateTime(2026, 3, 11, 9, 0, 0, DateTimeKind.Utc),
            SubmittedAt = new DateTime(2026, 3, 12, 9, 0, 0, DateTimeKind.Utc),
            HeureDebut = TimeSpan.FromHours(8), HeureFin = TimeSpan.FromHours(10), DureeMinutes = 120,
            Ville = "Lyon", CodePostal = "69000", Pays = "France", ClientContact = "M. X",
            TicketNumber = "T-1", ResolutionStatus = "resolu", AdditionalInterventionRequired = true,
            ProjectName = "P", ProjectNumber = "P-1", ProjectPhase = "etude", ProjectStatus = "termine",
            SiteID = 4242, ClientID = Guid.NewGuid(),
        };

        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<NovadisDbContext>();
            db.Sites.Add(new Site { Numero = 4242, NomDuSite = "Site référentiel" });
            db.CRIForms.Add(cri);
            await db.SaveChangesAsync();
        }

        using var readScope = _factory.Services.CreateScope();
        var readDb = readScope.ServiceProvider.GetRequiredService<NovadisDbContext>();
        var loaded = await readDb.CRIForms.AsNoTracking()
            .Where(c => c.Id == cri.Id)
            .WithoutHeavyColumns(readDb.Model)
            .SingleAsync();

        loaded.Data.Should().BeNull();
        loaded.TechnicianSignature.Should().BeNull();
        loaded.ClientSignature.Should().BeNull();
        loaded.Technician.Should().NotBeNull();
        loaded.Technician!.Id.Should().Be(techId);
        loaded.Site!.NomDuSite.Should().Be("Site référentiel");

        // Toute autre colonne mappée doit être recopiée — y compris celles ajoutées plus tard.
        var mapped = readDb.Model.FindEntityType(typeof(CRIForm))!.GetProperties()
            .Where(p => p.PropertyInfo != null && !CriProjections.HeavyColumns.Contains(p.Name));
        foreach (var property in mapped)
        {
            var info = property.PropertyInfo!;
            info.GetValue(loaded).Should().Be(info.GetValue(cri), because: $"{info.Name} doit être recopiée");
        }
    }
}
