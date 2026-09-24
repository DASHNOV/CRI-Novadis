namespace NovadisApi.Models
{
    /// <summary>
    /// Énumération des rôles utilisateur
    /// </summary>
    public enum UserRole
    {
        Technician,
        Admin
    }

    /// <summary>
    /// Extensions pour le rôle utilisateur
    /// </summary>
    public static class UserRoleExtensions
    {
        public static UserRole FromString(string role)
        {
            return role?.ToLower() switch
            {
                "admin" => UserRole.Admin,
                "technician" => UserRole.Technician,
                "technicien" => UserRole.Technician,
                _ => UserRole.Technician
            };
        }

        /// <summary>
        /// Forme canonique d'un rôle stocké ("Technicien" → "Technician").
        /// À utiliser partout où le rôle sort de la base (JWT, DTO) : les policies
        /// ne connaissent que "Technician" et "Admin".
        /// </summary>
        public static string Normalize(string role) => FromString(role).ToRoleString();

        public static string ToRoleString(this UserRole role)
        {
            return role switch
            {
                UserRole.Admin => "Admin",
                UserRole.Technician => "Technician",
                _ => "Technician"
            };
        }
    }
}
