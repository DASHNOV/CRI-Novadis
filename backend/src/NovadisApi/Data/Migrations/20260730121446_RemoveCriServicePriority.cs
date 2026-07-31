using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NovadisApi.Data.Migrations
{
    /// <inheritdoc />
    public partial class RemoveCriServicePriority : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_CRIForms_Priority",
                table: "CRIForms");

            migrationBuilder.DropColumn(
                name: "Priority",
                table: "CRIForms");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Priority",
                table: "CRIForms",
                type: "character varying(20)",
                maxLength: 20,
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_CRIForms_Priority",
                table: "CRIForms",
                column: "Priority");
        }
    }
}
