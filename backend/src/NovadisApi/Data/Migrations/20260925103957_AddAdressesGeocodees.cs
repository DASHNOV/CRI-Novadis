using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NovadisApi.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddAdressesGeocodees : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "AdressesGeocodees",
                columns: table => new
                {
                    Cle = table.Column<string>(type: "character varying(800)", maxLength: 800, nullable: false),
                    Latitude = table.Column<double>(type: "double precision", nullable: true),
                    Longitude = table.Column<double>(type: "double precision", nullable: true),
                    Score = table.Column<double>(type: "double precision", nullable: true),
                    Precision = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: true),
                    GeocodeLe = table.Column<DateTime>(type: "timestamp without time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AdressesGeocodees", x => x.Cle);
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "AdressesGeocodees");
        }
    }
}
