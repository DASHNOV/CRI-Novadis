using System.Net;
using System.Text;
using System.Text.Json;
using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using NovadisApi.Data;

namespace NovadisApi.Tests.Integration;

/// <summary>
/// Étape 1.3 du plan de remédiation : le corps de requête de POST/PUT /api/CRI ne
/// doit plus pouvoir décrire un graphe d'entités. Lier directement <c>CRIForm</c>
/// laissait un client joindre un <c>technician</c> ou des <c>photos</c> au payload,
/// qu'EF matérialisait — jusqu'à la création d'un utilisateur Admin.
/// </summary>
public class CRIInputDtoTests : IClassFixture<NovadisWebApplicationFactory>
{
    private readonly NovadisWebApplicationFactory _factory;
    private readonly Guid _userId = Guid.NewGuid();

    public CRIInputDtoTests(NovadisWebApplicationFactory factory)
    {
        _factory = factory;
    }

    private HttpClient CreateAuthenticatedClient() =>
        TestAuthHelper.CreateAuthenticatedClient(_factory.CreateClient(), _userId);

    private static StringContent Json(string raw) =>
        new(raw, Encoding.UTF8, "application/json");

    private async Task<T> QueryDbAsync<T>(Func<NovadisDbContext, Task<T>> query)
    {
        using var scope = _factory.Services.CreateScope();
        return await query(scope.ServiceProvider.GetRequiredService<NovadisDbContext>());
    }

    // ─── 1 : une entité Technician jointe au corps ne doit rien créer ─────────

    [Fact]
    public async Task CreateCRI_WithTechnicianNavigation_DoesNotCreateUser()
    {
        var usersBefore = await QueryDbAsync(db => db.Users.CountAsync());

        var response = await CreateAuthenticatedClient().PostAsync("/api/cri", Json("""
        {
          "interventionType": "Service",
          "category": "Maintenance",
          "interventionDate": "2026-09-08T08:00:00Z",
          "clientName": "Client Escalade",
          "technician": {
            "id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
            "email": "pirate@exemple.fr",
            "role": "Admin",
            "firstName": "Pirate",
            "lastName": "Escalade",
            "passwordHash": "x",
            "isActive": true
          }
        }
        """));

        response.StatusCode.Should().Be(HttpStatusCode.Created);

        var usersAfter = await QueryDbAsync(db => db.Users.CountAsync());
        usersAfter.Should().Be(usersBefore, "le corps de requête ne doit pas pouvoir insérer d'utilisateur");

        var pirateExists = await QueryDbAsync(db => db.Users.AnyAsync(u => u.Email == "pirate@exemple.fr"));
        pirateExists.Should().BeFalse();
    }

    // ─── 2 : des photos jointes au corps ne doivent rien créer ───────────────

    [Fact]
    public async Task CreateCRI_WithPhotosPayload_DoesNotCreatePhotoRows()
    {
        var photosBefore = await QueryDbAsync(db => db.CRIPhotos.CountAsync());

        var response = await CreateAuthenticatedClient().PostAsync("/api/cri", Json("""
        {
          "interventionType": "Service",
          "category": "Maintenance",
          "interventionDate": "2026-09-08T08:00:00Z",
          "clientName": "Client Photos",
          "photos": [
            { "id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb", "fileName": "injecte.jpg", "filePath": "/app/uploads/injecte.jpg" }
          ]
        }
        """));

        response.StatusCode.Should().Be(HttpStatusCode.Created);

        var photosAfter = await QueryDbAsync(db => db.CRIPhotos.CountAsync());
        photosAfter.Should().Be(photosBefore);
    }

    // ─── 3 : le propriétaire vient du jeton, pas du corps ────────────────────

    [Fact]
    public async Task CreateCRI_IgnoresClientSuppliedTechnicianId()
    {
        var response = await CreateAuthenticatedClient().PostAsync("/api/cri", Json("""
        {
          "interventionType": "Service",
          "category": "Maintenance",
          "interventionDate": "2026-09-08T08:00:00Z",
          "clientName": "Client Propriete",
          "technicianId": "cccccccc-cccc-cccc-cccc-cccccccccccc"
        }
        """));

        response.StatusCode.Should().Be(HttpStatusCode.Created);

        var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync()).RootElement;
        var criId = Guid.Parse(json.GetProperty("data").GetProperty("id").GetString()!);

        var ownerId = await QueryDbAsync(db => db.CRIForms
            .Where(c => c.Id == criId)
            .Select(c => c.TechnicianId)
            .SingleAsync());

        ownerId.Should().Be(_userId);
    }

    // ─── 4 : le payload exact des APK en circulation (règle 3) ───────────────

    [Fact]
    public async Task CreateCRI_WithLegacyMobilePayload_Returns201()
    {
        var criId = Guid.NewGuid();

        // Les 16 clés de saveCriProjet / saveCriService (cri_remote_repository.dart).
        var response = await CreateAuthenticatedClient().PostAsync("/api/cri", Json($$"""
        {
          "id": "{{criId}}",
          "interventionType": "Project",
          "category": "Installation",
          "interventionDate": "2026-09-08T08:00:00Z",
          "clientName": "Client Legacy",
          "clientAddress": "12 rue des Tests",
          "clientSite": "Site Legacy",
          "clientPhone": "0102030405",
          "clientEmail": "contact@legacy.fr",
          "workDescription": "Description des travaux",
          "materialsUsed": "Cable, connecteurs",
          "duration": 2.5,
          "status": "Submitted",
          "technicianSignature": "data:image/png;base64,AAAA",
          "clientSignature": "data:image/png;base64,BBBB",
          "data": "{\"projectName\":\"Chantier Legacy\",\"ville\":\"Lyon\"}"
        }
        """));

        response.StatusCode.Should().Be(HttpStatusCode.Created);

        var cri = await QueryDbAsync(db => db.CRIForms.AsNoTracking().SingleAsync(c => c.Id == criId));

        // Un champ absent du DTO serait silencieusement perdu à la synchronisation :
        // on vérifie donc chacun d'eux, pas seulement le code de retour.
        cri.InterventionType.Should().Be("Project");
        cri.Category.Should().Be("Installation");
        cri.ClientName.Should().Be("Client Legacy");
        cri.ClientAddress.Should().Be("12 rue des Tests");
        cri.ClientSite.Should().Be("Site Legacy");
        cri.ClientPhone.Should().Be("0102030405");
        cri.ClientEmail.Should().Be("contact@legacy.fr");
        cri.WorkDescription.Should().Be("Description des travaux");
        cri.MaterialsUsed.Should().Be("Cable, connecteurs");
        cri.Duration.Should().Be(2.5m);
        cri.Status.Should().Be("Submitted");
        cri.TechnicianSignature.Should().Be("data:image/png;base64,AAAA");
        cri.ClientSignature.Should().Be("data:image/png;base64,BBBB");
        cri.Data.Should().Contain("Chantier Legacy");
        // ExtractDataFields continue de dériver les colonnes issues de Data.
        cri.ProjectName.Should().Be("Chantier Legacy");
        cri.Ville.Should().Be("Lyon");
        cri.SubmittedAt.Should().NotBeNull();
    }

    // ─── 5 : statut hors de l'ensemble autorisé → 400 ────────────────────────

    [Fact]
    public async Task CreateCRI_WithInvalidStatus_Returns400()
    {
        var response = await CreateAuthenticatedClient().PostAsync("/api/cri", Json("""
        {
          "interventionType": "Service",
          "category": "Maintenance",
          "interventionDate": "2026-09-08T08:00:00Z",
          "clientName": "Client Statut",
          "status": "Archived"
        }
        """));

        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task UpdateCRI_WithInvalidStatus_Returns400()
    {
        var client = CreateAuthenticatedClient();

        var create = await client.PostAsync("/api/cri", Json("""
        {
          "interventionType": "Service",
          "category": "Maintenance",
          "interventionDate": "2026-09-08T08:00:00Z",
          "clientName": "Client Statut Update"
        }
        """));
        create.StatusCode.Should().Be(HttpStatusCode.Created);

        var criId = JsonDocument.Parse(await create.Content.ReadAsStringAsync())
            .RootElement.GetProperty("data").GetProperty("id").GetString();

        var response = await client.PutAsync($"/api/cri/{criId}", Json("""
        {
          "interventionType": "Service",
          "category": "Maintenance",
          "interventionDate": "2026-09-08T08:00:00Z",
          "clientName": "Client Statut Update",
          "status": "Admin"
        }
        """));

        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }
}
