using FluentAssertions;

namespace NovadisApi.Tests.Integration;

/// <summary>
/// Étape 2.3 du plan de remédiation : seule une origine listée dans
/// Cors:AllowedOrigins obtient un canal authentifié vers l'API.
/// </summary>
public class CorsPolicyTests : IClassFixture<NovadisWebApplicationFactory>
{
    private readonly NovadisWebApplicationFactory _factory;

    public CorsPolicyTests(NovadisWebApplicationFactory factory)
    {
        _factory = factory;
    }

    private async Task<HttpResponseMessage> PreflightAsync(string origin)
    {
        var request = new HttpRequestMessage(HttpMethod.Options, "/api/health/live");
        request.Headers.Add("Origin", origin);
        request.Headers.Add("Access-Control-Request-Method", "GET");
        return await _factory.CreateClient().SendAsync(request);
    }

    [Theory]
    [InlineData("https://attaquant.vercel.app")]
    [InlineData("https://cri-novadis-evil.vercel.app")]
    [InlineData("https://cri-novadis.tech.attaquant.com")]
    public async Task Preflight_FromUnlistedOrigin_HasNoAllowOriginHeader(string origin)
    {
        var response = await PreflightAsync(origin);

        response.Headers.Contains("Access-Control-Allow-Origin").Should().BeFalse();
    }

    [Fact]
    public async Task Preflight_FromProductionOrigin_IsAllowedWithCredentials()
    {
        var response = await PreflightAsync("https://cri-novadis.tech");

        response.Headers.GetValues("Access-Control-Allow-Origin").Should().ContainSingle("https://cri-novadis.tech");
        response.Headers.GetValues("Access-Control-Allow-Credentials").Should().ContainSingle("true");
    }
}
