namespace NovadisApi.Models
{
    /// <summary>
    /// Énumération des rôles utilisateur
    /// </summary>
    public enum UserRole
    {
        Technician,
        Admin,
        Supervisor
    }

    /// <summary>
    /// Valeurs canoniques des rôles, telles que stockées en base et émises dans le JWT.
    /// </summary>
    public static class RoleNames
    {
        public const string Technician = "Technician";
        public const string Admin = "Admin";
        public const string Supervisor = "Supervisor";
    }

    /// <summary>
    /// Extensions pour le rôle utilisateur
    /// </summary>
    public static class UserRoleExtensions
    {
        /// <summary>
        /// Rôle reconnu, ou <c>null</c> pour une valeur inconnue. Pas de repli sur
        /// Technician : un rôle mal saisi en base donnerait sinon le droit de créer
        /// des CRI (cf. docs/plan-role-superviseur.md §3).
        /// </summary>
        public static UserRole? FromString(string? role)
        {
            return role?.Trim().ToLowerInvariant() switch
            {
                "admin" => UserRole.Admin,
                "technician" => UserRole.Technician,
                "technicien" => UserRole.Technician,
                "supervisor" => UserRole.Supervisor,
                _ => null
            };
        }

        public static string ToRoleString(this UserRole role)
        {
            return role switch
            {
                UserRole.Admin => RoleNames.Admin,
                UserRole.Supervisor => RoleNames.Supervisor,
                _ => RoleNames.Technician
            };
        }

        /// <summary>
        /// Forme canonique d'un rôle stocké ("Technicien" → "Technician").
        /// À utiliser partout où le rôle sort de la base (JWT, DTO) : les policies
        /// ne connaissent que les valeurs de <see cref="RoleNames"/>. Un rôle
        /// inconnu est renvoyé tel quel — il ne correspond à aucune capacité.
        /// </summary>
        public static string Normalize(string role) => FromString(role)?.ToRoleString() ?? role;
    }
}
