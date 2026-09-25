using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace NovadisApi.Models
{
    [Table("Sites")]
    public class Site
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int Numero { get; set; }

        [Required]
        [MaxLength(500)]
        public string NomDuSite { get; set; } = string.Empty;

        [MaxLength(500)]
        public string? Adresse { get; set; }

        [MaxLength(255)]
        public string? Ville { get; set; }

        [MaxLength(20)]
        public string? CodePostal { get; set; }

        [MaxLength(100)]
        public string? Pays { get; set; }

        [MaxLength(255)]
        public string? ResponsableDorigine { get; set; }

        public DateTime? DateDeCreation { get; set; }

        // ── Géocodage (carte des sites) ──

        /// <summary>WGS84. <c>null</c> : pas encore géocodé, ou résultat trop incertain.</summary>
        public double? Latitude { get; set; }

        public double? Longitude { get; set; }

        /// <summary>Score de confiance du géocodeur (0–1), conservé même sous le seuil (« à vérifier »).</summary>
        public double? GeocodageScore { get; set; }

        /// <summary>Précision du résultat : <c>housenumber</c>, <c>street</c>, <c>locality</c>, <c>municipality</c>.</summary>
        [MaxLength(20)]
        public string? GeocodagePrecision { get; set; }

        /// <summary>Dernière tentative de géocodage ; <c>null</c> : à géocoder (nouveau site ou adresse modifiée).</summary>
        public DateTime? GeocodeLe { get; set; }

        /// <summary>Coordonnées placées à la main : le géocodage automatique ne les écrase jamais.</summary>
        public bool CoordonneesManuelles { get; set; }
    }
}
