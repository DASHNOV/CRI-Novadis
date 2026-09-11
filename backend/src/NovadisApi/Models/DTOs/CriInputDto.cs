using System.ComponentModel.DataAnnotations;

namespace NovadisApi.Models.DTOs
{
    /// <summary>
    /// Corps de requête accepté par POST /api/CRI et PUT /api/CRI/{id}.
    ///
    /// Reprend **exactement** les 16 clés envoyées par le frontend
    /// (`cri_remote_repository.dart`, `saveCriProjet` et `saveCriService`) et
    /// **aucune propriété de navigation**. C'est la barrière : lier directement
    /// l'entité <see cref="CRIForm"/> laissait un client décrire un graphe
    /// d'entités — un `technician` ou des `photos` dans le corps étaient
    /// matérialisés par EF, ce qui permettait de créer un utilisateur Admin.
    ///
    /// Règle 3 du plan de remédiation : des APK anciens rejouent des CRI au format
    /// d'une version antérieure. Tout champ retiré d'ici devient un champ
    /// silencieusement perdu à la synchronisation, sans erreur visible.
    /// Ne jamais réduire cette liste sans la confronter aux deux méthodes du
    /// dépôt Flutter ligne à ligne.
    /// </summary>
    public sealed class CriInputDto
    {
        /// <summary>
        /// Identifiant choisi par le client (les CRI sont créés hors ligne).
        /// Sur POST, un identifiant déjà connu vaut mise à jour du CRI existant.
        /// </summary>
        public Guid? Id { get; set; }

        [Required]
        [MaxLength(50)]
        public string InterventionType { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string Category { get; set; } = string.Empty;

        [Required]
        public DateTime InterventionDate { get; set; }

        [Required]
        [MaxLength(255)]
        public string ClientName { get; set; } = string.Empty;

        [MaxLength(255)]
        public string? ClientAddress { get; set; }

        [MaxLength(255)]
        public string? ClientSite { get; set; }

        [MaxLength(20)]
        public string? ClientPhone { get; set; }

        // Regex reprise telle quelle de CRIForm.ClientEmail : alignée sur la
        // validation frontend (form_validators.dart). Laisse passer null et
        // chaîne vide — l'e-mail client est optionnel.
        [RegularExpression(
            @"^[a-zA-Z0-9!#$%&*+/=?^_`{|}~-]+(?:\.[a-zA-Z0-9!#$%&*+/=?^_`{|}~-]+)*@[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$",
            ErrorMessage = "Format d'email invalide")]
        [MaxLength(255)]
        public string? ClientEmail { get; set; }

        public string? WorkDescription { get; set; }

        public string? MaterialsUsed { get; set; }

        /// <summary>Durée en heures.</summary>
        public decimal? Duration { get; set; }

        [MaxLength(50)]
        public string Status { get; set; } = DraftStatus;

        /// <summary>JSON complet du modèle Flutter, source de ExtractDataFields.</summary>
        public string? Data { get; set; }

        /// <summary>Base64.</summary>
        public string? TechnicianSignature { get; set; }

        /// <summary>Base64.</summary>
        public string? ClientSignature { get; set; }

        public const string DraftStatus = "Draft";

        /// <summary>
        /// Statuts acceptés en entrée. Le client choisissait auparavant librement
        /// cette valeur, y compris des statuts inconnus du reste de l'application.
        /// </summary>
        public static readonly IReadOnlySet<string> AllowedStatuses =
            new HashSet<string>(StringComparer.Ordinal) { DraftStatus, "Submitted", "Validated" };

        public bool HasValidStatus() => AllowedStatuses.Contains(Status);
    }
}
