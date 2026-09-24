using System.Net;
using System.Net.Http.Json;
using FluentAssertions;
using Microsoft.Extensions.DependencyInjection;
using NovadisApi.Data;
using NovadisApi.Models;
using NovadisApi.Models.DTOs;

namespace NovadisApi.Tests.Integration;

/// <summary>
/// Étape 2.2 du plan de remédiation : l'autocomplétion clients / sites ne propose
/// que les CRI visibles par l'appelant (les siens, ou tous avec CriReadAll), et le
/// référentiel des sites n'est plus public.
/// </summary>
public class SearchScopingTests : IClassFixture<NovadisWebApplicationFactory>, IAsyncLifetime
{
    private readonly NovadisWebApplicationFactory _factory;

    private readonly Guid _techA = Guid.NewGuid();
    private readonly Guid _techB = Guid.NewGuid();

    // Suffixe unique : la base en mémoire est partagée par les tests de la classe.
    private readonly string _tag = Guid.NewGuid().ToString("N")[..8];
    private string ClientA => $"Client A {_tag}";
    private string ClientB => $"Client B {_tag}";

    public SearchScopingTests(NovadisWebApplicationFactory factory)
    {
        _factory = factory;
    }

    public async Task InitializeAsync()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<NovadisDbContext>();
        db.CRIForms.Add(NewCri(_techA, ClientA, $"Site A {_tag}"));
        db.CRIForms.Add(NewCri(_techB, ClientB, $"Site B {_tag}"));
        await db.SaveChangesAsync();
    }

    public Task DisposeAsync() => Task.CompletedTask;

    private static CRIForm NewCri(Guid technicianId, string client, string site) => new()
    {
        Id = Guid.NewGuid(),
        TechnicianId = technicianId,
        InterventionType = "Service",
        Category = "Maintenance",
        InterventionDate = DateTime.UtcNow,
        ClientName = client,
        ClientSite = site,
        Status = "Submitted",
    };

    private HttpClient Client(Guid userId, string role) =>
        TestAuthHelper.CreateAuthenticatedClient(_factory.CreateClient(), userId, role);

    private async Task<List<string>> SearchAsync(HttpClient client, string url)
    {
        var response = await client.GetAsync(url);
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<ApiResponse<List<string>>>();
        return body!.Data!;
    }

    [Fact]
    public async Task SearchClients_AsTechnician_ReturnsOnlyOwnClients()
    {
        var clients = await SearchAsync(Client(_techA, RoleNames.Technician), $"/api/CRI/clients/search?q={_tag}");

        clients.Should().BeEquivalentTo(ClientA);
    }

    [Fact]
    public async Task SearchSites_AsTechnician_ReturnsOnlyOwnSites()
    {
        var sites = await SearchAsync(Client(_techA, RoleNames.Technician), $"/api/CRI/sites/search?q={_tag}");

        sites.Should().BeEquivalentTo($"Site A {_tag}");
    }

    [Fact]
    public async Task SearchSites_AsTechnician_ForOtherTechniciansClient_ReturnsNothing()
    {
        var sites = await SearchAsync(Client(_techA, RoleNames.Technician),
            $"/api/CRI/sites/search?client={Uri.EscapeDataString(ClientB)}&q={_tag}");

        sites.Should().BeEmpty();
    }

    [Theory]
    [InlineData(RoleNames.Admin)]
    [InlineData(RoleNames.Supervisor)]
    public async Task SearchClients_WithCriReadAll_ReturnsAllClients(string role)
    {
        var clients = await SearchAsync(Client(Guid.NewGuid(), role), $"/api/CRI/clients/search?q={_tag}");

        clients.Should().BeEquivalentTo(ClientA, ClientB);
    }

    [Theory]
    [InlineData("/api/CRI/clients/search?q=a")]
    [InlineData("/api/CRI/sites/search?q=a")]
    [InlineData("/api/Sites/search?q=paris")]
    public async Task Search_WithoutToken_Returns401(string url)
    {
        var response = await _factory.CreateClient().GetAsync(url);

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }
}
