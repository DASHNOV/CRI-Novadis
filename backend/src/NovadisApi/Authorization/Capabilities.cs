using System.Security.Claims;
using NovadisApi.Models;

namespace NovadisApi.Authorization
{
    /// <summary>
    /// Capacités de l'application et rôles qui les détiennent — <b>seule source de
    /// vérité</b> des droits. Chaque capacité est enregistrée comme policy du même
    /// nom (<c>[Authorize(Policy = Capabilities.X)]</c>) dans <c>Program.cs</c>.
    /// Miroir côté Flutter : <c>frontend/lib/core/constants/permissions.dart</c>.
    ///
    /// Ne jamais tester un rôle directement (<c>IsInRole("Admin")</c>) : ajouter ou
    /// utiliser une capacité.
    /// </summary>
    public static class Capabilities
    {
        /// <summary>Créer / modifier ses CRI, signature client, photos.</summary>
        public const string CriCreate = nameof(CriCreate);

        /// <summary>Lire les CRI de tous les techniciens (sinon : les siens).</summary>
        public const string CriReadAll = nameof(CriReadAll);

        /// <summary>Modifier les brouillons et supprimer les CRI / photos d'autrui.</summary>
        public const string CriManageAny = nameof(CriManageAny);

        /// <summary>Statistiques personnelles (<c>/api/personal</c>).</summary>
        public const string PersonalStats = nameof(PersonalStats);

        /// <summary>Statistiques globales et tableaux de bord (<c>/api/global</c>).</summary>
        public const string GlobalStats = nameof(GlobalStats);

        /// <summary>Exports portant sur tous les techniciens (sinon : ses CRI).</summary>
        public const string ExportAll = nameof(ExportAll);

        /// <summary>Voir / télécharger les documents exportés par tous.</summary>
        public const string DocumentsReadAll = nameof(DocumentsReadAll);

        /// <summary>Renommer / supprimer / partager les documents d'autrui.</summary>
        public const string DocumentsManageAny = nameof(DocumentsManageAny);

        /// <summary>Administration technique : import des sites, santé de l'API.</summary>
        public const string SystemAdmin = nameof(SystemAdmin);

        public static readonly IReadOnlyDictionary<string, string[]> RolesByCapability =
            new Dictionary<string, string[]>
            {
                [CriCreate] = [RoleNames.Technician, RoleNames.Admin],
                [CriReadAll] = [RoleNames.Admin, RoleNames.Supervisor],
                [CriManageAny] = [RoleNames.Admin],
                [PersonalStats] = [RoleNames.Technician, RoleNames.Admin],
                [GlobalStats] = [RoleNames.Admin, RoleNames.Supervisor],
                [ExportAll] = [RoleNames.Admin, RoleNames.Supervisor],
                [DocumentsReadAll] = [RoleNames.Admin, RoleNames.Supervisor],
                [DocumentsManageAny] = [RoleNames.Admin],
                [SystemAdmin] = [RoleNames.Admin],
            };

        /// <summary>
        /// Contrôle inline, pour les règles qui combinent capacité et propriété
        /// (« propriétaire ou <see cref="CriReadAll"/> »).
        /// </summary>
        public static bool HasCapability(this ClaimsPrincipal user, string capability) =>
            RolesByCapability.TryGetValue(capability, out var roles) && roles.Any(user.IsInRole);
    }
}
