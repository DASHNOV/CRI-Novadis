using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NovadisApi.Data.Migrations
{
    /// <summary>
    /// Régularise un schéma qui avait divergé du modèle EF.
    ///
    /// Contexte (cf. docs/resolved-issues.md, 2026-09-07) : deux migrations avaient
    /// été écrites à la main sans fichier .Designer.cs, donc sans attribut
    /// [Migration]. EF ne les a jamais découvertes et ne les a jamais exécutées.
    /// Résultat, deux écarts opposés selon l'environnement :
    ///
    ///   - en production, "SavedSignature" a été ajoutée directement en base et
    ///     "Priority" n'a jamais été supprimée ;
    ///   - sur une base neuve, InitialCreate crée "Priority" et ignore
    ///     "SavedSignature" — l'endpoint PUT /api/users/me/signature échouerait.
    ///
    /// Le SQL ci-dessous est idempotent pour couvrir les deux cas avec le même
    /// code, et rester rejouable sans dommage.
    ///
    /// Volontairement absent : les AlterColumn timestamptz -> timestamp que le
    /// scaffolding avait générés. Ils découlent de Npgsql.EnableLegacyTimestampBehavior
    /// (Program.cs) actif au design-time, réécriraient toutes les colonnes de dates
    /// de la base et feraient perdre l'information de fuseau. Cet écart entre le
    /// modèle et le schéma est antérieur et sans effet à l'exécution ; le traiter
    /// relève d'un chantier distinct.
    /// </summary>
    public partial class SyncSchemaWithModel : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"ALTER TABLE ""Users"" ADD COLUMN IF NOT EXISTS ""SavedSignature"" text;");

            migrationBuilder.Sql(@"DROP INDEX IF EXISTS ""IX_CRIForms_Priority"";");
            migrationBuilder.Sql(@"ALTER TABLE ""CRIForms"" DROP COLUMN IF EXISTS ""Priority"";");

            // L'ancienne migration écrite à la main avait été enregistrée à la main
            // elle aussi, pour éviter qu'EF ne rejoue son ADD COLUMN. Le fichier
            // ayant disparu, la ligne d'historique n'a plus de référent.
            migrationBuilder.Sql(@"DELETE FROM ""__EFMigrationsHistory"" WHERE ""MigrationId"" = '20260624000000_AddUserSavedSignature';");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"ALTER TABLE ""CRIForms"" ADD COLUMN IF NOT EXISTS ""Priority"" character varying(20);");
            migrationBuilder.Sql(@"CREATE INDEX IF NOT EXISTS ""IX_CRIForms_Priority"" ON ""CRIForms"" (""Priority"");");

            migrationBuilder.Sql(@"ALTER TABLE ""Users"" DROP COLUMN IF EXISTS ""SavedSignature"";");
        }
    }
}
