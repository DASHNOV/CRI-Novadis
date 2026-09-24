using System.Net;
using System.Net.Http.Json;
using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using NovadisApi.Data;
using NovadisApi.Models;
using NovadisApi.Models.DTOs;
using NovadisApi.Services.Auth;

namespace NovadisApi.Tests.Integration;

/// <summary>
/// Étape 2.4 du plan de remédiation : la base ne contient ni code OTP, ni jeton
/// de session exploitable — seulement des condensats.
/// </summary>
public class AuthSecretsStorageTests : IClassFixture<NovadisWebApplicationFactory>
{
    private const string Code = "246810";

    private readonly NovadisWebApplicationFactory _factory;

    public AuthSecretsStorageTests(NovadisWebApplicationFactory factory)
    {
        _factory = factory;
    }

    private NovadisDbContext Db(IServiceScope scope) => scope.ServiceProvider.GetRequiredService<NovadisDbContext>();

    /// <summary>Connexion OTP complète ; renvoie la réponse et l'e-mail utilisé.</summary>
    private async Task<(AuthResponseDto Auth, string Email)> SignInAsync()
    {
        var userId = Guid.NewGuid();
        var email = $"secrets-{userId:N}@novadis.fr";
        await TestDataSeeder.SeedUserAsync(_factory, userId, email);

        using (var scope = _factory.Services.CreateScope())
        {
            var codes = scope.ServiceProvider.GetRequiredService<ICodeGeneratorService>();
            var salt = codes.GenerateSalt();
            Db(scope).AuthAttempts.Add(new AuthAttempt
            {
                Email = email,
                CodeHash = codes.HashCode(Code, salt),
                CodeSalt = salt,
                ExpiresAt = DateTime.UtcNow.AddMinutes(10),
            });
            await Db(scope).SaveChangesAsync();
        }

        var response = await _factory.CreateClient().PostAsJsonAsync("/api/auth/verify", new { email, code = Code });
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<ApiResponse<AuthResponseDto>>();
        return (body!.Data!, email);
    }

    private async Task<UserToken> StoredTokenAsync(string email)
    {
        using var scope = _factory.Services.CreateScope();
        return await Db(scope).UserTokens.AsNoTracking()
            .Where(t => t.User!.Email == email)
            .OrderByDescending(t => t.CreatedAt)
            .FirstAsync();
    }

    [Fact]
    public async Task RequestCode_StoresSaltedHash_NotTheCode()
    {
        var userId = Guid.NewGuid();
        var email = $"otp-{userId:N}@novadis.fr";
        await TestDataSeeder.SeedUserAsync(_factory, userId, email);

        (await _factory.CreateClient().PostAsJsonAsync("/api/auth/login", new { email }))
            .StatusCode.Should().Be(HttpStatusCode.OK);

        using var scope = _factory.Services.CreateScope();
        var attempt = await Db(scope).AuthAttempts.SingleAsync(a => a.Email == email);
        Convert.FromBase64String(attempt.CodeSalt).Should().HaveCount(16);
        Convert.FromBase64String(attempt.CodeHash).Should().HaveCount(32);
    }

    [Fact]
    public async Task SignIn_StoresOnlyHashesOfSessionTokens()
    {
        var (auth, email) = await SignInAsync();

        var stored = await StoredTokenAsync(email);

        stored.RefreshTokenHash.Should().Be(TokenHasher.Hash(auth.RefreshToken))
            .And.NotBe(auth.RefreshToken);
        auth.TrustedDeviceToken.Should().NotBeNullOrEmpty();
        stored.TrustedDeviceTokenHash.Should().Be(TokenHasher.Hash(auth.TrustedDeviceToken!))
            .And.NotBe(auth.TrustedDeviceToken);
    }

    [Fact]
    public async Task Refresh_WithIssuedToken_Succeeds_AndRotates()
    {
        var (auth, _) = await SignInAsync();
        var client = _factory.CreateClient();

        var first = await client.PostAsJsonAsync("/api/auth/refresh", new { refreshToken = auth.RefreshToken });
        first.StatusCode.Should().Be(HttpStatusCode.OK);

        // Le jeton consommé est révoqué : le rejouer échoue.
        var replay = await client.PostAsJsonAsync("/api/auth/refresh", new { refreshToken = auth.RefreshToken });
        replay.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Refresh_WithStoredHashInsteadOfToken_Fails()
    {
        // Ce qu'un attaquant lirait dans une copie de la base ne donne pas de session.
        var (_, email) = await SignInAsync();
        var stored = await StoredTokenAsync(email);

        var response = await _factory.CreateClient()
            .PostAsJsonAsync("/api/auth/refresh", new { refreshToken = stored.RefreshTokenHash });

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task VerifyDevice_WithIssuedToken_Succeeds_AndStoredHashFails()
    {
        var (auth, email) = await SignInAsync();
        var stored = await StoredTokenAsync(email);
        var client = _factory.CreateClient();

        (await client.PostAsJsonAsync("/api/auth/verify-device",
                new { email, trustedDeviceToken = stored.TrustedDeviceTokenHash }))
            .StatusCode.Should().Be(HttpStatusCode.Unauthorized);

        (await client.PostAsJsonAsync("/api/auth/verify-device",
                new { email, trustedDeviceToken = auth.TrustedDeviceToken }))
            .StatusCode.Should().Be(HttpStatusCode.OK);
    }
}
