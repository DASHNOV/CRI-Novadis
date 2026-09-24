using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using FluentAssertions;
using Microsoft.Extensions.DependencyInjection;
using NovadisApi.Data;
using NovadisApi.Models;

namespace NovadisApi.Tests.Integration;

/// <summary>
/// Rôle Supervisor (docs/plan-role-superviseur.md §4) : lit tout, n'écrit rien
/// sur les CRI, gère uniquement ses propres documents exportés.
/// </summary>
public class SupervisorAuthorizationTests : IClassFixture<NovadisWebApplicationFactory>, IAsyncLifetime
{
    private readonly NovadisWebApplicationFactory _factory;

    private readonly Guid _tech = Guid.NewGuid();
    private readonly Guid _supervisor = Guid.NewGuid();

    private readonly Guid _cri = Guid.NewGuid();
    private readonly Guid _photo = Guid.NewGuid();
    private readonly Guid _techDoc = Guid.NewGuid();
    private readonly Guid _supervisorDoc = Guid.NewGuid();

    public SupervisorAuthorizationTests(NovadisWebApplicationFactory factory)
    {
        _factory = factory;
    }

    public async Task InitializeAsync()
    {
        await TestDataSeeder.SeedUserAsync(_factory, _tech, $"tech-{_tech}@novadis.fr");
        await TestDataSeeder.SeedUserAsync(_factory, _supervisor, $"sup-{_supervisor}@novadis.fr", RoleNames.Supervisor);

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<NovadisDbContext>();
        db.CRIForms.Add(new CRIForm
        {
            Id = _cri,
            TechnicianId = _tech,
            InterventionType = "Service",
            Category = "Maintenance",
            InterventionDate = DateTime.UtcNow,
            ClientName = "Client Superviseur",
            Status = "Draft",
        });
        db.CRIPhotos.Add(new CRIPhoto
        {
            Id = _photo,
            CRIFormId = _cri,
            StoragePath = "missing/photo.jpg",
            OriginalFileName = "photo.jpg",
            MimeType = "image/jpeg",
            UploadedAt = DateTime.UtcNow,
        });
        db.ExportedDocuments.Add(NewDoc(_techDoc, _tech));
        db.ExportedDocuments.Add(NewDoc(_supervisorDoc, _supervisor));
        await db.SaveChangesAsync();
    }

    public Task DisposeAsync() => Task.CompletedTask;

    private static ExportedDocument NewDoc(Guid id, Guid userId) => new()
    {
        Id = id,
        UserId = userId,
        Filename = $"{id}.xlsx",
        FileType = "xlsx",
        ExportType = "cri",
        StoragePath = $"missing/{id}.xlsx",
    };

    private HttpClient Supervisor =>
        TestAuthHelper.CreateAuthenticatedClient(_factory.CreateClient(), _supervisor, RoleNames.Supervisor);

    private static void Allowed(HttpResponseMessage r) =>
        r.StatusCode.Should().NotBe(HttpStatusCode.Forbidden)
            .And.NotBe(HttpStatusCode.Unauthorized);

    private static void Denied(HttpResponseMessage r) =>
        r.StatusCode.Should().Be(HttpStatusCode.Forbidden);

    private object CriBody => new
    {
        id = _cri,
        interventionType = "Service",
        category = "Maintenance",
        interventionDate = DateTime.UtcNow,
        clientName = "Client Superviseur",
        status = "Draft",
    };

    // ─── Lecture : autorisée ─────────────────────────────────────────────────

    [Fact]
    public async Task ListCris_ReturnsCrisOfAllTechnicians()
    {
        var response = await Supervisor.GetAsync("/api/cri");

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync()).RootElement;
        json.GetProperty("data").EnumerateArray()
            .Select(c => c.GetProperty("id").GetGuid())
            .Should().Contain(_cri);
    }

    [Fact]
    public async Task GetCri_And_Photo_OfATechnician_Allowed()
    {
        (await Supervisor.GetAsync($"/api/cri/{_cri}")).StatusCode.Should().Be(HttpStatusCode.OK);
        Allowed(await Supervisor.GetAsync($"/api/cri/{_cri}/photos/{_photo}"));
    }

    [Theory]
    [InlineData("/api/global/technicians")]
    [InlineData("/api/global/activity")]
    [InlineData("/api/users/me")]
    [InlineData("/api/sites?page=1&pageSize=10")]
    public async Task ReadEndpoints_Allowed(string url)
    {
        Allowed(await Supervisor.GetAsync(url));
    }

    [Fact]
    public async Task ExportedDocuments_SeesDocumentsOfEveryone()
    {
        var response = await Supervisor.GetAsync("/api/exported-documents");

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        (await response.Content.ReadAsStringAsync()).Should().Contain(_techDoc.ToString());
        Allowed(await Supervisor.GetAsync($"/api/exported-documents/{_techDoc}/download"));
    }

    [Fact]
    public async Task PeriodExport_HasGlobalScope()
    {
        (await Supervisor.GetAsync("/api/export/period.xlsx?range=month"))
            .StatusCode.Should().Be(HttpStatusCode.OK);

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<NovadisDbContext>();
        db.ExportedDocuments
            .Where(d => d.UserId == _supervisor && d.ExportType != "cri")
            .Select(d => d.Metadata)
            .Should().ContainSingle().Which.Should().Contain("\"scope\":\"global\"");
    }

    [Fact]
    public async Task OwnDocument_CanBeRenamed()
    {
        (await Supervisor.PatchAsJsonAsync($"/api/exported-documents/{_supervisorDoc}", new { filename = "mon-export.xlsx" }))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);
    }

    [Fact]
    public async Task GlobalTechnicianList_ExcludesSupervisors()
    {
        var body = await (await Supervisor.GetAsync("/api/global/technicians")).Content.ReadAsStringAsync();

        body.Should().Contain(_tech.ToString()).And.NotContain(_supervisor.ToString());
    }

    [Fact]
    public async Task UsersTechnicianList_ExcludesSupervisors()
    {
        var body = await (await Supervisor.GetAsync("/api/users/technicians")).Content.ReadAsStringAsync();

        body.Should().Contain(_tech.ToString()).And.NotContain(_supervisor.ToString());
    }

    // ─── Écriture sur les CRI : refusée ──────────────────────────────────────

    [Fact]
    public async Task CreateCri_Denied()
    {
        var body = new
        {
            interventionType = "Service",
            category = "Maintenance",
            interventionDate = DateTime.UtcNow,
            clientName = "Tentative",
            status = "Draft",
        };
        Denied(await Supervisor.PostAsJsonAsync("/api/cri", body));
    }

    [Fact]
    public async Task UpdateCri_Denied() =>
        Denied(await Supervisor.PutAsJsonAsync($"/api/cri/{_cri}", CriBody));

    [Fact]
    public async Task ClientSignature_Denied() =>
        Denied(await Supervisor.PatchAsJsonAsync($"/api/cri/{_cri}/signature", new { clientSignature = "MANUAL_VALIDATION" }));

    [Fact]
    public async Task DeleteCri_Denied() =>
        Denied(await Supervisor.DeleteAsync($"/api/cri/{_cri}"));

    [Fact]
    public async Task UploadPhoto_Denied() =>
        Denied(await Supervisor.PostAsync($"/api/cri/{_cri}/photos", new MultipartFormDataContent()));

    [Fact]
    public async Task DeletePhoto_Denied() =>
        Denied(await Supervisor.DeleteAsync($"/api/cri/{_cri}/photos/{_photo}"));

    // ─── Hors périmètre : refusé ─────────────────────────────────────────────

    [Theory]
    [InlineData("/api/personal/recent")]
    [InlineData("/api/health")]
    [InlineData("/api/health/stats")]
    public async Task OutOfScopeReads_Denied(string url) =>
        Denied(await Supervisor.GetAsync(url));

    [Fact]
    public async Task SitesImport_Denied() =>
        Denied(await Supervisor.PostAsync("/api/sites/import", null));

    [Fact]
    public async Task ManageDocumentOfAnotherUser_Denied()
    {
        Denied(await Supervisor.PatchAsJsonAsync($"/api/exported-documents/{_techDoc}", new { filename = "x.xlsx" }));
        Denied(await Supervisor.PostAsync($"/api/exported-documents/{_techDoc}/mark-shared", null));
        Denied(await Supervisor.DeleteAsync($"/api/exported-documents/{_techDoc}"));
    }

    // ─── Connexion ───────────────────────────────────────────────────────────

    [Fact]
    public async Task SupervisorAccount_CanRequestLoginCode()
    {
        var response = await _factory.CreateClient()
            .PostAsJsonAsync("/api/auth/login", new { email = $"sup-{_supervisor}@novadis.fr" });

        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }
}
