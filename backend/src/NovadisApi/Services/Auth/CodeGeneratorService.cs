using System.Security.Cryptography;
using System.Text;

namespace NovadisApi.Services.Auth
{
    public interface ICodeGeneratorService
    {
        string GenerateCode(int length = 6);
        string GenerateSalt();
        string HashCode(string code, string salt);
        bool VerifyCode(string code, string hash, string salt);
    }

    public class CodeGeneratorService : ICodeGeneratorService
    {
        /// <summary>
        /// Génère un code numérique aléatoire (cryptographiquement sûr)
        /// </summary>
        public string GenerateCode(int length = 6)
        {
            var code = new char[length];
            for (int i = 0; i < length; i++)
            {
                code[i] = (char)('0' + RandomNumberGenerator.GetInt32(0, 10));
            }
            return new string(code);
        }

        /// <summary>
        /// Sel aléatoire de 16 octets, un par tentative, stocké en base64 avec le condensat.
        /// </summary>
        public string GenerateSalt() => Convert.ToBase64String(RandomNumberGenerator.GetBytes(16));

        /// <summary>
        /// HMAC-SHA256 du code, clé = sel de la tentative. Le sel empêche une table
        /// précalculée commune à toutes les tentatives (l'ancien sel constant, en dur).
        /// </summary>
        public string HashCode(string code, string salt)
        {
            var hash = HMACSHA256.HashData(Convert.FromBase64String(salt), Encoding.UTF8.GetBytes(code));
            return Convert.ToBase64String(hash);
        }

        /// <summary>
        /// Vérifie un code en temps constant : la durée de comparaison ne révèle pas
        /// combien d'octets du condensat correspondent.
        /// </summary>
        public bool VerifyCode(string code, string hash, string salt)
        {
            byte[] expected;
            try { expected = Convert.FromBase64String(hash); }
            catch (FormatException) { return false; }

            var actual = Convert.FromBase64String(HashCode(code, salt));
            return CryptographicOperations.FixedTimeEquals(actual, expected);
        }
    }
}
