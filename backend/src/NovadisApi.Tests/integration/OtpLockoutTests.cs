using System.Net;
using System.Net.Http.Json;
using FluentAssertions;
using Microsoft.Extensions.DependencyInjection;
using NovadisApi.Data;
using NovadisApi.Models;
using NovadisApi.Services.Auth;

namespace NovadisApi.Tests.Integration;

/// <summary>
/// Étape 2.1 du plan de remédiation : verrouillage de l'e-mail après
/// Auth:MaxFailedAttempts (5) codes erronés sur Auth:LockoutDurationMinutes (30).
/// </summary>
public class OtpLockoutTests : IClassFixture<NovadisWebApplicationFactory>
{
    private const string GoodCode = "123456";
    private const string WrongCode = "000000";

    private readonly NovadisWebApplicationFactory _factory;

    public OtpLockoutTests(NovadisWebApplicationFactory factory)
    {
        _factory = factory;
    }

    // Un e-mail par test : la base en mémoire est partagée par la classe.
    private async Task<string> SeedUserAsync()
    {
        var userId = Guid.NewGuid();
        var email = $"lockout-{userId:N}@novadis.fr";
        await TestDataSeeder.SeedUserAsync(_factory, userId, email);
        return email;
    }

    private async Task SeedAttemptAsync(string email, string code, DateTime? createdAt = null, int failedAttempts = 0)
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<NovadisDbContext>();
        var codes = scope.ServiceProvider.GetRequiredService<ICodeGeneratorService>();
        var created = createdAt ?? DateTime.UtcNow;
        var salt = codes.GenerateSalt();
        db.AuthAttempts.Add(new AuthAttempt
        {
            Email = email,
            CodeHash = codes.HashCode(code, salt),
            CodeSalt = salt,
            CreatedAt = created,
            // Une tentative ancienne est aussi expirée, comme en production.
            ExpiresAt = createdAt == null ? DateTime.UtcNow.AddMinutes(10) : created.AddMinutes(10),
            FailedAttempts = failedAttempts,
        });
        await db.SaveChangesAsync();
    }

    private Task<HttpResponseMessage> VerifyAsync(string email, string code) =>
        _factory.CreateClient().PostAsJsonAsync("/api/auth/verify", new { email, code });

    [Fact]
    public async Task VerifyCode_AfterFiveFailures_Returns429_EvenWithCorrectCode()
    {
        var email = await SeedUserAsync();
        await SeedAttemptAsync(email, GoodCode);

        for (var i = 0; i < 5; i++)
            (await VerifyAsync(email, WrongCode)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);

        var response = await VerifyAsync(email, GoodCode);

        response.StatusCode.Should().Be(HttpStatusCode.TooManyRequests);
        (await response.Content.ReadAsStringAsync()).Should().Contain("Trop de tentatives");
    }

    [Fact]
    public async Task VerifyCode_FailuresSpreadOverSeveralCodes_StillLocks()
    {
        // Redemander un code ne remet pas le compteur à zéro.
        var email = await SeedUserAsync();
        await SeedAttemptAsync(email, "111111", failedAttempts: 3);
        await SeedAttemptAsync(email, GoodCode, failedAttempts: 2);

        (await VerifyAsync(email, GoodCode)).StatusCode.Should().Be(HttpStatusCode.TooManyRequests);
    }

    [Fact]
    public async Task VerifyCode_AfterLockoutWindow_AllowsRetry()
    {
        var email = await SeedUserAsync();
        await SeedAttemptAsync(email, "111111", createdAt: DateTime.UtcNow.AddMinutes(-31), failedAttempts: 5);
        await SeedAttemptAsync(email, GoodCode);

        (await VerifyAsync(email, GoodCode)).StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task VerifyCode_Success_ResetsFailureCount()
    {
        var email = await SeedUserAsync();
        await SeedAttemptAsync(email, GoodCode);
        for (var i = 0; i < 4; i++)
            await VerifyAsync(email, WrongCode);
        (await VerifyAsync(email, GoodCode)).StatusCode.Should().Be(HttpStatusCode.OK);

        // Sans remise à zéro, ce cinquième échec verrouillerait un utilisateur légitime.
        await SeedAttemptAsync(email, "654321");
        await VerifyAsync(email, WrongCode);

        await SeedAttemptAsync(email, GoodCode);
        (await VerifyAsync(email, GoodCode)).StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task RequestCode_WhileLocked_Returns429()
    {
        var email = await SeedUserAsync();
        await SeedAttemptAsync(email, GoodCode, failedAttempts: 5);

        var response = await _factory.CreateClient().PostAsJsonAsync("/api/auth/login", new { email });

        response.StatusCode.Should().Be(HttpStatusCode.TooManyRequests);
    }
}
