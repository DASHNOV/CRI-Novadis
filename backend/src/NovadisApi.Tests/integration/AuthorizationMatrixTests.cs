using System.Net;
using System.Net.Http.Json;
using FluentAssertions;
using Microsoft.Extensions.DependencyInjection;
using NovadisApi.Data;
using NovadisApi.Models;

namespace NovadisApi.Tests.Integration;

/// <summary>
/// Matrice des droits par rôle (docs/plan-role-superviseur.md §4) : chaque ligne
/// de <c>Capabilities.RolesByCapability</c> est vérifiée sur un endpoint réel.
/// Un « autorisé » s'assure seulement que la réponse n'est ni 401 ni 403 : la
/// base en mémoire ne supporte pas toutes les requêtes des services de stats.
/// </summary>
public class AuthorizationMatrixTests : IClassFixture<NovadisWebApplicationFactory>, IAsyncLifetime
{
    private readonly NovadisWebApplicationFactory _factory;

    private readonly Guid _owner = Guid.NewGuid();      // technicien propriétaire des données
    private readonly Guid _otherTech = Guid.NewGuid();  // autre technicien
    private readonly Guid _admin = Guid.NewGuid();

    private readonly Guid _draftCri = Guid.NewGuid();
    private readonly Guid _submittedCri = Guid.NewGuid();
    private readonly Guid _ownerDoc = Guid.NewGuid();

    public AuthorizationMatrixTests(NovadisWebApplicationFactory factory)
    {
        _factory = factory;
    }

    public async Task InitializeAsync()
    {
        await TestDataSeeder.SeedUserAsync(_factory, _owner, $"owner-{_owner}@novadis.fr");
        await TestDataSeeder.SeedUserAsync(_factory, _otherTech, $"other-{_otherTech}@novadis.fr");
        await TestDataSeeder.SeedUserAsync(_factory, _admin, $"admin-{_admin}@novadis.fr", RoleNames.Admin);

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<NovadisDbContext>();
        db.CRIForms.Add(NewCri(_draftCri, "Draft"));
        db.CRIForms.Add(NewCri(_submittedCri, "Submitted"));
        db.ExportedDocuments.Add(new ExportedDocument
        {
            Id = _ownerDoc,
            UserId = _owner,
            Filename = "export.xlsx",
            FileType = "xlsx",
            ExportType = "cri",
            StoragePath = "missing/export.xlsx",
        });
        await db.SaveChangesAsync();
    }

    public Task DisposeAsync() => Task.CompletedTask;

    private CRIForm NewCri(Guid id, string status) => new()
    {
        Id = id,
        TechnicianId = _owner,
        InterventionType = "Service",
        Category = "Maintenance",
        InterventionDate = DateTime.UtcNow,
        ClientName = "Client Matrice",
        Status = status,
    };

    private Guid CriToDelete()
    {
        var id = Guid.NewGuid();
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<NovadisDbContext>();
        db.CRIForms.Add(NewCri(id, "Draft"));
        db.SaveChanges();
        return id;
    }

    private HttpClient As(Guid userId, string role) =>
        TestAuthHelper.CreateAuthenticatedClient(_factory.CreateClient(), userId, role);

    private HttpClient OtherTech => As(_otherTech, RoleNames.Technician);
    private HttpClient Admin => As(_admin, RoleNames.Admin);

    private static void Allowed(HttpResponseMessage r) =>
        r.StatusCode.Should().NotBe(HttpStatusCode.Forbidden)
            .And.NotBe(HttpStatusCode.Unauthorized);

    private static void Denied(HttpResponseMessage r) =>
        r.StatusCode.Should().Be(HttpStatusCode.Forbidden);

    private static object DraftBody(Guid id) => new
    {
        id,
        interventionType = "Service",
        category = "Maintenance",
        interventionDate = DateTime.UtcNow,
        clientName = "Client Matrice",
        status = "Draft",
    };

    // ─── CriReadAll ──────────────────────────────────────────────────────────

    [Fact]
    public async Task GetCri_OfAnotherTechnician_TechnicianDenied_AdminAllowed()
    {
        Denied(await OtherTech.GetAsync($"/api/cri/{_draftCri}"));
        Allowed(await Admin.GetAsync($"/api/cri/{_draftCri}"));
    }

    // ─── CriManageAny ────────────────────────────────────────────────────────

    [Fact]
    public async Task DeleteCri_OfAnotherTechnician_TechnicianDenied_AdminAllowed()
    {
        Denied(await OtherTech.DeleteAsync($"/api/cri/{CriToDelete()}"));
        (await Admin.DeleteAsync($"/api/cri/{CriToDelete()}")).StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task UpdateDraft_OfAnotherTechnician_TechnicianDenied_AdminAllowed()
    {
        Denied(await OtherTech.PutAsJsonAsync($"/api/cri/{_draftCri}", DraftBody(_draftCri)));
        (await Admin.PutAsJsonAsync($"/api/cri/{_draftCri}", DraftBody(_draftCri)))
            .StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task UpdateSubmitted_OfAnotherTechnician_DeniedEvenForAdmin()
    {
        Denied(await Admin.PutAsJsonAsync($"/api/cri/{_submittedCri}", DraftBody(_submittedCri)));
    }

    [Fact]
    public async Task ClientSignature_IsStrictOwnerOnly()
    {
        var body = new { clientSignature = "MANUAL_VALIDATION" };
        Denied(await Admin.PatchAsJsonAsync($"/api/cri/{_submittedCri}/signature", body));
        (await As(_owner, RoleNames.Technician).PatchAsJsonAsync($"/api/cri/{_submittedCri}/signature", body))
            .StatusCode.Should().Be(HttpStatusCode.OK);
    }

    // ─── Stats ───────────────────────────────────────────────────────────────

    [Fact]
    public async Task GlobalStats_TechnicianDenied_AdminAllowed()
    {
        Denied(await OtherTech.GetAsync("/api/global/technicians"));
        Allowed(await Admin.GetAsync("/api/global/technicians"));
    }

    [Fact]
    public async Task PersonalStats_TechnicianAndAdminAllowed()
    {
        Allowed(await OtherTech.GetAsync("/api/personal/recent"));
        Allowed(await Admin.GetAsync("/api/personal/recent"));
    }

    // ─── SystemAdmin ─────────────────────────────────────────────────────────

    [Fact]
    public async Task SitesImport_TechnicianDenied()
    {
        Denied(await OtherTech.PostAsync("/api/sites/import", null));
    }

    // ─── Documents exportés ──────────────────────────────────────────────────

    [Fact]
    public async Task DownloadDocument_OfAnotherUser_TechnicianDenied_AdminAllowed()
    {
        Denied(await OtherTech.GetAsync($"/api/exported-documents/{_ownerDoc}/download"));
        Allowed(await Admin.GetAsync($"/api/exported-documents/{_ownerDoc}/download"));
    }

    [Fact]
    public async Task RenameDocument_OfAnotherUser_TechnicianDenied_AdminAllowed()
    {
        var body = new { filename = "renomme.xlsx" };
        Denied(await OtherTech.PatchAsJsonAsync($"/api/exported-documents/{_ownerDoc}", body));
        Allowed(await Admin.PatchAsJsonAsync($"/api/exported-documents/{_ownerDoc}", body));
    }

    // ─── Rôle inconnu ────────────────────────────────────────────────────────

    [Fact]
    public async Task UnknownRoleToken_CannotCreateCri()
    {
        var client = As(Guid.NewGuid(), "Hyperviseur");
        Denied(await client.PostAsJsonAsync("/api/cri", DraftBody(Guid.NewGuid())));
    }

    [Fact]
    public async Task UnknownRoleInDatabase_CannotRequestLoginCode()
    {
        var id = Guid.NewGuid();
        var email = $"unknown-{id}@novadis.fr";
        await TestDataSeeder.SeedUserAsync(_factory, id, email, "Hyperviseur");

        var response = await _factory.CreateClient().PostAsJsonAsync("/api/auth/login", new { email });

        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }
}
