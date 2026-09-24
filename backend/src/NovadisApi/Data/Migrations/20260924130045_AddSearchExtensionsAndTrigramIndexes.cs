using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NovadisApi.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddSearchExtensionsAndTrigramIndexes : Migration
    {
        /// <summary>
        /// Étape 4.4 du plan de remédiation. Extensions déclarées dans le modèle
        /// (CREATE EXTENSION IF NOT EXISTS : sans effet là où elles existent déjà, comme
        /// unaccent en production, créée à la main). Index GIN trigramme sur les
        /// expressions exactes que génère l'autocomplétion — lower(col) LIKE '%q%' — :
        /// EF ne sait pas modéliser un index sur expression, d'où le SQL brut.
        /// </summary>
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterDatabase()
                .Annotation("Npgsql:PostgresExtension:pg_trgm", ",,")
                .Annotation("Npgsql:PostgresExtension:unaccent", ",,");

            migrationBuilder.Sql(@"CREATE INDEX IF NOT EXISTS ""IX_CRIForms_ClientName_trgm""
                ON ""CRIForms"" USING gin (lower(""ClientName"") gin_trgm_ops);");
            migrationBuilder.Sql(@"CREATE INDEX IF NOT EXISTS ""IX_CRIForms_ClientSite_trgm""
                ON ""CRIForms"" USING gin (lower(""ClientSite"") gin_trgm_ops);");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"DROP INDEX IF EXISTS ""IX_CRIForms_ClientName_trgm"";");
            migrationBuilder.Sql(@"DROP INDEX IF EXISTS ""IX_CRIForms_ClientSite_trgm"";");

            // Les extensions restent : unaccent existait avant cette migration en production,
            // et la supprimer casserait /api/Sites/search.
        }
    }
}
