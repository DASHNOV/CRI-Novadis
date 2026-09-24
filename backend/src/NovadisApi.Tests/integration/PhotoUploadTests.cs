using System.Net;
using System.Net.Http.Headers;
using FluentAssertions;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using NovadisApi.Data;
using NovadisApi.Models;

namespace NovadisApi.Tests.Integration;

/// <summary>
/// Étape 4.2 du plan de remédiation : l'app rejoue désormais l'envoi des photos
/// après un échec. Le serveur doit donc être idempotent, et refuser explicitement
/// un fichier invalide au lieu de l'ignorer en répondant 200.
/// </summary>
public class PhotoUploadTests : IClassFixture<NovadisWebApplicationFactory>, IAsyncLifetime
{
    private readonly NovadisWebApplicationFactory _factory;
    private readonly Guid _tech = Guid.NewGuid();
    private readonly Guid _cri = Guid.NewGuid();

    public PhotoUploadTests(NovadisWebApplicationFactory factory)
    {
        _factory = factory;
    }

    public async Task InitializeAsync()
    {
        await TestDataSeeder.SeedUserAsync(_factory, _tech, $"photo-{_tech:N}@novadis.fr");
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<NovadisDbContext>();
        db.CRIForms.Add(new CRIForm
        {
            Id = _cri, TechnicianId = _tech, InterventionType = "Service", Category = "Maintenance",
            InterventionDate = DateTime.UtcNow, ClientName = "Client photos", Status = "Submitted",
        });
        await db.SaveChangesAsync();
    }

    public Task DisposeAsync()
    {
        // Les fichiers sont réellement écrits sous uploads/cri-photos/<id> du projet API.
        var env = _factory.Services.GetRequiredService<IWebHostEnvironment>();
        var dir = Path.Combine(env.ContentRootPath, "uploads", "cri-photos", _cri.ToString());
        if (Directory.Exists(dir)) Directory.Delete(dir, recursive: true);
        return Task.CompletedTask;
    }

    private static ByteArrayContent Image(int bytes, string mime = "image/jpeg")
    {
        var content = new ByteArrayContent(new byte[bytes]);
        content.Headers.ContentType = new MediaTypeHeaderValue(mime);
        return content;
    }

    private Task<HttpResponseMessage> UploadAsync(params (string Name, ByteArrayContent Content)[] files)
    {
        var form = new MultipartFormDataContent();
        foreach (var (name, content) in files) form.Add(content, "files", name);
        return TestAuthHelper.CreateAuthenticatedClient(_factory.CreateClient(), _tech)
            .PostAsync($"/api/cri/{_cri}/photos", form);
    }

    private async Task<int> PhotoCountAsync()
    {
        using var scope = _factory.Services.CreateScope();
        return await scope.ServiceProvider.GetRequiredService<NovadisDbContext>()
            .CRIPhotos.CountAsync(p => p.CRIFormId == _cri);
    }

    [Fact]
    public async Task Upload_ReplayedAfterFailure_DoesNotDuplicatePhotos()
    {
        (await UploadAsync(("a.jpg", Image(1000)), ("b.jpg", Image(2000)))).StatusCode.Should().Be(HttpStatusCode.OK);

        // L'app rejoue l'envoi complet (délai dépassé alors que le serveur avait tout reçu),
        // avec une troisième photo prise entre-temps.
        (await UploadAsync(("a.jpg", Image(1000)), ("b.jpg", Image(2000)), ("c.jpg", Image(3000))))
            .StatusCode.Should().Be(HttpStatusCode.OK);

        (await PhotoCountAsync()).Should().Be(3);
    }

    [Fact]
    public async Task Upload_SameNameDifferentSize_IsANewPhoto()
    {
        await UploadAsync(("image.jpg", Image(1000)));
        await UploadAsync(("image.jpg", Image(1500)));

        (await PhotoCountAsync()).Should().Be(2);
    }

    [Fact]
    public async Task Upload_OversizedFile_Returns400_AndSavesNothing()
    {
        var response = await UploadAsync(("ok.jpg", Image(1000)), ("enorme.jpg", Image(11 * 1024 * 1024)));

        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        (await response.Content.ReadAsStringAsync()).Should().Contain("enorme.jpg");
        (await PhotoCountAsync()).Should().Be(0, "une photo valide envoyée avec une invalide ne doit pas être à moitié enregistrée");
    }

    [Fact]
    public async Task Upload_UnsupportedType_Returns400_WithReason()
    {
        var response = await UploadAsync(("doc.pdf", Image(1000, "application/pdf")));

        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        (await response.Content.ReadAsStringAsync()).Should().Contain("doc.pdf").And.Contain("non accepté");
    }
}
