using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NovadisApi.Data.Migrations
{
    /// <inheritdoc />
    public partial class HashAuthSecrets : Migration
    {
        /// <summary>
        /// Étape 2.4 du plan de remédiation. Écrit à partir du scaffolding CLI, qui
        /// supprimait les colonnes de jetons avant d'ajouter les condensats (vides) :
        /// toutes les sessions perdues, et l'index unique en échec dès deux lignes.
        /// Ici les jetons existants sont convertis sur place — même expression que
        /// <c>TokenHasher.Hash</c> — et les techniciens restent connectés.
        /// </summary>
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Codes OTP en cours (≤ 10 min) : sans sel, ils ne sont plus vérifiables.
            // Effet : un utilisateur en pleine connexion redemande un code.
            migrationBuilder.Sql(@"DELETE FROM ""AuthAttempts"";");

            migrationBuilder.AddColumn<string>(
                name: "CodeSalt",
                table: "AuthAttempts",
                type: "character varying(32)",
                maxLength: 32,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "RefreshTokenHash",
                table: "UserTokens",
                type: "character varying(64)",
                maxLength: 64,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "TrustedDeviceTokenHash",
                table: "UserTokens",
                type: "character varying(64)",
                maxLength: 64,
                nullable: true);

            // Doit rester identique à TokenHasher.Hash : Base64(SHA-256(UTF-8(jeton))).
            migrationBuilder.Sql(@"
                UPDATE ""UserTokens"" SET
                    ""RefreshTokenHash"" = encode(sha256(convert_to(""RefreshToken"", 'UTF8')), 'base64'),
                    ""TrustedDeviceTokenHash"" = CASE WHEN ""TrustedDeviceToken"" IS NULL THEN NULL
                        ELSE encode(sha256(convert_to(""TrustedDeviceToken"", 'UTF8')), 'base64') END;");

            migrationBuilder.Sql(@"ALTER TABLE ""UserTokens"" ALTER COLUMN ""RefreshTokenHash"" SET NOT NULL;");

            migrationBuilder.DropIndex(
                name: "IX_UserTokens_RefreshToken",
                table: "UserTokens");

            migrationBuilder.DropColumn(
                name: "RefreshToken",
                table: "UserTokens");

            migrationBuilder.DropColumn(
                name: "TrustedDeviceToken",
                table: "UserTokens");

            migrationBuilder.CreateIndex(
                name: "IX_UserTokens_RefreshTokenHash",
                table: "UserTokens",
                column: "RefreshTokenHash",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_UserTokens_TrustedDeviceTokenHash",
                table: "UserTokens",
                column: "TrustedDeviceTokenHash");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_UserTokens_RefreshTokenHash",
                table: "UserTokens");

            migrationBuilder.DropIndex(
                name: "IX_UserTokens_TrustedDeviceTokenHash",
                table: "UserTokens");

            migrationBuilder.DropColumn(
                name: "RefreshTokenHash",
                table: "UserTokens");

            migrationBuilder.DropColumn(
                name: "TrustedDeviceTokenHash",
                table: "UserTokens");

            migrationBuilder.DropColumn(
                name: "CodeSalt",
                table: "AuthAttempts");

            migrationBuilder.AddColumn<string>(
                name: "RefreshToken",
                table: "UserTokens",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "TrustedDeviceToken",
                table: "UserTokens",
                type: "character varying(128)",
                maxLength: 128,
                nullable: true);

            // Un condensat ne redonne pas le jeton : chaque ligne reçoit une valeur
            // unique inutilisable et toutes les sessions sont révoquées.
            migrationBuilder.Sql(@"UPDATE ""UserTokens"" SET ""RefreshToken"" = ""Id""::text, ""IsRevoked"" = true, ""RevokedReason"" = 'hash_rollback';");
            migrationBuilder.Sql(@"DELETE FROM ""AuthAttempts"";");

            migrationBuilder.CreateIndex(
                name: "IX_UserTokens_RefreshToken",
                table: "UserTokens",
                column: "RefreshToken",
                unique: true);
        }
    }
}
