using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using NovadisApi.Data;
using NovadisApi.Services.Stats;

namespace NovadisApi.Tests.Services;

/// <summary>
/// Les tests d'intégration tournent sur la base InMemory, qui évalue tout en C# :
/// une requête intraduisible en SQL y passe et ne casse qu'en production. Ici, chaque
/// méthode de <see cref="GlobalStatsService"/> s'exécute sur le vrai fournisseur Npgsql
/// pointé vers un port fermé : la traduction LINQ → SQL a lieu avant la connexion,
/// donc l'échec attendu est la connexion (<see cref="NpgsqlException"/>), jamais
/// « could not be translated ».
/// </summary>
public class StatsSqlTranslationTests
{
    private static NovadisDbContext UnreachableNpgsqlContext() =>
        new(new DbContextOptionsBuilder<NovadisDbContext>()
            .UseNpgsql("Host=127.0.0.1;Port=1;Database=none;Username=none;Password=none;Timeout=1")
            .Options);

    private static readonly StatsFilter FullFilter = StatsFilter.LastDays(30) with
    {
        To = DateTime.UtcNow.Date.AddDays(1),
        TechnicianId = Guid.NewGuid(),
        Site = "Site",
    };

    public static TheoryData<string> Methods() => new()
    {
        "global", "by-site", "by-technician", "distribution", "evolution", "evolution-all-time", "recent",
    };

    [Theory]
    [MemberData(nameof(Methods))]
    public async Task Query_TranslatesToSql(string method)
    {
        await using var context = UnreachableNpgsqlContext();
        var service = new GlobalStatsService(context);

        Func<Task> act = method switch
        {
            "global" => () => service.GetGlobalStatsAsync(FullFilter),
            "by-site" => () => service.GetStatsBySiteAsync(FullFilter),
            "by-technician" => () => service.GetStatsByTechnicianAsync(FullFilter),
            "distribution" => () => service.GetDistributionStatsAsync(FullFilter),
            "evolution" => () => service.GetEvolutionAsync(FullFilter),
            "evolution-all-time" => () => service.GetEvolutionAsync(StatsFilter.All with { Site = "Site" }),
            "recent" => () => service.GetRecentInterventionsAsync(FullFilter, 10),
            _ => throw new ArgumentOutOfRangeException(nameof(method)),
        };

        // EF enveloppe l'échec de connexion (« likely due to a transient failure ») :
        // on cherche la NpgsqlException dans la chaîne.
        var thrown = (await act.Should().ThrowAsync<Exception>()).Which;
        Exception? e = thrown;
        while (e is not null and not NpgsqlException) e = e.InnerException;
        e.Should().NotBeNull($"la requête doit se traduire en SQL puis échouer à la connexion, pas : {thrown.Message}");
    }
}
