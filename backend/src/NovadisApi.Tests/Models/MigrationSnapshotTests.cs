using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using NovadisApi.Data;

namespace NovadisApi.Tests.Models;

/// <summary>
/// Le modèle EF compilé doit correspondre au snapshot des migrations. Depuis EF Core 9,
/// un écart fait échouer <c>Migrate()</c> au démarrage (PendingModelChangesWarning) :
/// l'API ne démarre plus. C'est arrivé en production avec une propriété déclarée sous
/// <c>#if DEBUG</c> — présente dans le snapshot généré en Debug, absente du build Release.
/// La CI exécute les tests en Release : ce test y voit le modèle de production.
/// </summary>
public class MigrationSnapshotTests
{
    [Fact]
    public void CompiledModel_MatchesMigrationSnapshot()
    {
        // Même bascule que Program.cs : sans elle, les colonnes de dates diffèrent.
        AppContext.SetSwitch("Npgsql.EnableLegacyTimestampBehavior", true);

        // Aucune connexion ouverte : la comparaison porte sur le modèle et le snapshot.
        var options = new DbContextOptionsBuilder<NovadisDbContext>()
            .UseNpgsql("Host=unused;Database=unused")
            .Options;
        using var db = new NovadisDbContext(options);

        db.Database.HasPendingModelChanges().Should().BeFalse(
            "le modèle diverge du snapshot : générer une migration (dotnet ef migrations add), " +
            "et ne jamais conditionner une propriété mappée à #if DEBUG");
    }
}
