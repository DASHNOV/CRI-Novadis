using System.Net;
using FluentAssertions;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.DependencyInjection;
using NovadisApi.Models;
using NovadisApi.Services.Export;

namespace NovadisApi.Tests.Integration;

/// <summary>
/// Garde de non-régression sur l'étape 1.2 du plan de remédiation : une erreur de
/// génération d'export ne doit jamais renvoyer au client le message d'exception,
/// son type ou sa trace de pile — seul le journal serveur les contient.
/// </summary>
public class ExportControllerErrorTests : IClassFixture<NovadisWebApplicationFactory>
{
    private readonly NovadisWebApplicationFactory _factory;

    public ExportControllerErrorTests(NovadisWebApplicationFactory factory)
    {
        _factory = factory;
    }

    private HttpClient CreateClientWithFailingExport()
    {
        var factory = _factory.WithWebHostBuilder(builder =>
            builder.ConfigureServices(services =>
            {
                var descriptor = services.SingleOrDefault(d => d.ServiceType == typeof(IXlsxExportService));
                if (descriptor != null) services.Remove(descriptor);
                services.AddScoped<IXlsxExportService, ThrowingXlsxExportService>();
            }));

        return TestAuthHelper.CreateAuthenticatedClient(factory.CreateClient(), Guid.NewGuid());
    }

    [Theory]
    [InlineData("/api/export/cri/11111111-1111-1111-1111-111111111111.xlsx")]
    [InlineData("/api/export/period.xlsx?range=year")]
    public async Task Export_WhenGenerationThrows_Returns500_WithoutExceptionDetails(string path)
    {
        var response = await CreateClientWithFailingExport().GetAsync(path);

        response.StatusCode.Should().Be(HttpStatusCode.InternalServerError);

        var body = await response.Content.ReadAsStringAsync();
        body.Should().NotContain("stack");
        body.Should().NotContain("StackTrace");
        body.Should().NotContain(ThrowingXlsxExportService.SecretMessage);
        body.Should().NotContain(nameof(InvalidTimeZoneException));
        body.Should().Contain("La génération de l'export a échoué.");
    }
}

/// <summary>Service d'export qui échoue systématiquement, pour provoquer le catch.</summary>
public class ThrowingXlsxExportService : IXlsxExportService
{
    public const string SecretMessage = "chemin interne /app/export-storage/secret.xlsx";

    public Task<(byte[] Bytes, string Filename)?> GenerateSingleCriAsync(Guid criId, Guid requesterId, bool isAdmin)
        => throw new InvalidTimeZoneException(SecretMessage);

    public Task<(byte[] Bytes, string Filename)> GeneratePeriodAsync(
        ExportPeriod period, DateTime referenceDate, Guid requesterId, bool isAdmin,
        ExportDetailLevel detailLevel = ExportDetailLevel.Full)
        => throw new InvalidTimeZoneException(SecretMessage);
}
