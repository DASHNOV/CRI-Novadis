using System.Security.Cryptography;
using System.Text;

namespace NovadisApi.Services.Auth
{
    /// <summary>
    /// Condensat stocké à la place des jetons de session (refresh, appareil de confiance).
    /// SHA-256 simple, sans sel ni KDF lent : les jetons portent 48 à 64 octets
    /// d'entropie, aucune attaque par dictionnaire n'est possible.
    /// Doit rester identique à l'expression SQL de la migration HashAuthSecrets :
    /// <c>encode(sha256(convert_to(jeton, 'UTF8')), 'base64')</c>.
    /// </summary>
    public static class TokenHasher
    {
        public static string Hash(string token) =>
            Convert.ToBase64String(SHA256.HashData(Encoding.UTF8.GetBytes(token)));
    }
}
