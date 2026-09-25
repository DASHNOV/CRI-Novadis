using System.Text.RegularExpressions;

namespace NovadisApi.Services.Geocoding;

/// <summary>Clé d'une adresse de CRI dans le cache <c>AdressesGeocodees</c>.</summary>
public static partial class AddressKey
{
    [GeneratedRegex(@"\s+")]
    private static partial Regex Spaces();

    private static string Part(string? value) =>
        Spaces().Replace((value ?? "").Trim(), " ").ToLowerInvariant();

    /// <summary><c>null</c> si rien à géocoder (ni adresse, ni code postal, ni ville).</summary>
    public static string? From(string? adresse, string? codePostal, string? ville)
    {
        var key = $"{Part(adresse)}|{Part(codePostal)}|{Part(ville)}";
        return key == "||" ? null : key;
    }

    /// <summary>Retrouve les trois parties d'une clé (pour l'envoyer au géocodeur).</summary>
    public static (string Adresse, string CodePostal, string Ville) Split(string key)
    {
        var parts = key.Split('|');
        return (parts[0], parts.Length > 1 ? parts[1] : "", parts.Length > 2 ? parts[2] : "");
    }
}
