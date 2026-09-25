using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace NovadisApi.Models
{
    /// <summary>
    /// Cache de géocodage des adresses saisies dans les CRI, pour placer sur la carte
    /// les sites hors référentiel (saisie libre, sans <see cref="CRIForm.SiteID"/>).
    /// Une ligne par adresse distincte : jamais d'appel au géocodeur à la lecture des stats.
    /// </summary>
    [Table("AdressesGeocodees")]
    public class AdresseGeocodee
    {
        /// <summary>Clé normalisée (<c>AddressKey.From</c>) : adresse|code postal|ville.</summary>
        [Key]
        [MaxLength(800)]
        public string Cle { get; set; } = string.Empty;

        public double? Latitude { get; set; }

        public double? Longitude { get; set; }

        public double? Score { get; set; }

        [MaxLength(20)]
        public string? Precision { get; set; }

        public DateTime GeocodeLe { get; set; }
    }
}
