using System.Net;
using System.Text.Json;
using FluentAssertions;

namespace NovadisApi.Tests.Integration;

public class HealthControllerTests : IClassFixture<NovadisWebApplicationFactory>
{
    private readonly NovadisWebApplicationFactory _factory;

    public HealthControllerTests(NovadisWebApplicationFactory factory)
    {
        _factory = factory;
    }

    private HttpClient CreateClient(string? role = null) =>
        role is null
            ? _factory.CreateClient()
            : TestAuthHelper.CreateAuthenticatedClient(_factory.CreateClient(), Guid.NewGuid(), role);

    // ─── Liveness : reste anonyme (sonde Docker + monitoring externe) ─────────

    [Fact]
    public async Task Live_WithoutToken_ReturnsOk_WithAliveStatus()
    {
        var response = await CreateClient().GetAsync("/api/health/live");

        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var body = await response.Content.ReadAsStringAsync();
        var json = JsonDocument.Parse(body).RootElement;
        json.GetProperty("status").GetString().Should().Be("alive");
    }

    // ─── Readiness : administrateurs uniquement ──────────────────────────────

    [Fact]
    public async Task Get_WithoutToken_Returns401()
    {
        var response = await CreateClient().GetAsync("/api/health");

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Get_WithTechnicianToken_Returns403()
    {
        var response = await CreateClient("Technician").GetAsync("/api/health");

        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    [Fact]
    public async Task Get_WithAdminToken_ReturnsHealthy()
    {
        var response = await CreateClient("Admin").GetAsync("/api/health");

        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var body = await response.Content.ReadAsStringAsync();
        var json = JsonDocument.Parse(body).RootElement;
        json.GetProperty("status").GetString().Should().Be("healthy");
    }

    // ─── Stats : administrateurs uniquement, sans données nominatives ────────

    [Fact]
    public async Task Stats_WithoutToken_Returns401()
    {
        var response = await CreateClient().GetAsync("/api/health/stats");

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Stats_WithTechnicianToken_Returns403()
    {
        var response = await CreateClient("Technician").GetAsync("/api/health/stats");

        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    [Fact]
    public async Task Stats_WithAdminToken_ReturnsCounts_WithoutClientNames()
    {
        var response = await CreateClient("Admin").GetAsync("/api/health/stats");

        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var body = await response.Content.ReadAsStringAsync();
        var json = JsonDocument.Parse(body).RootElement;
        json.GetProperty("users").GetInt32().Should().Be(0);
        json.GetProperty("criForms").GetInt32().Should().Be(0);
        // `recentCris` exposait des noms de clients : la projection ne doit plus le contenir.
        json.TryGetProperty("recentCris", out _).Should().BeFalse();
    }

    // ─── Actions « pour test » supprimées ────────────────────────────────────

    [Theory]
    [InlineData("/api/health/users")]
    [InlineData("/api/health/test-write")]
    public async Task RemovedTestEndpoints_AreGone(string path)
    {
        var response = await CreateClient("Admin").GetAsync(path);

        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }
}
