namespace NovadisApi.Services.Stats;

/// <summary>
/// Regroupement des sites saisis librement : « Test », « test » et « test  » sont le
/// même site. La clé ignore la casse et les espaces en bord ; le nom affiché est la
/// graphie la plus fréquente. Même règle en SQL dans <see cref="StatsFilter.Apply"/>
/// (<c>lower(btrim(...))</c>) : ne modifier l'une sans l'autre.
/// </summary>
public static class SiteNames
{
    public static string Key(string? name) => (name ?? "").Trim().ToLowerInvariant();

    /// <summary>Clé → graphie la plus fréquente (à égalité : ordre alphabétique).</summary>
    public static Dictionary<string, string> DisplayNames(IEnumerable<string?> names) =>
        names
            .Where(n => !string.IsNullOrWhiteSpace(n))
            .Select(n => n!.Trim())
            .GroupBy(Key)
            .ToDictionary(
                g => g.Key,
                g => g.GroupBy(n => n)
                    .OrderByDescending(v => v.Count())
                    .ThenBy(v => v.Key, StringComparer.Ordinal)
                    .First().Key);
}
