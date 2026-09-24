/// Rôles utilisateur. Valeurs API alignées sur `RoleNames` côté back.
enum UserRole {
  technician('Technician', 'Technicien'),
  admin('Admin', 'Administrateur'),
  supervisor('Supervisor', 'Superviseur');

  const UserRole(this.apiValue, this.label);

  /// Valeur stockée en base et émise dans le JWT.
  final String apiValue;

  /// Libellé affiché dans l'interface.
  final String label;

  /// Rôle reconnu, ou `null` pour une valeur inconnue. Pas de repli sur
  /// technicien : un rôle non géré par cette version de l'app ne doit pas
  /// ouvrir l'espace de création de CRI (cf. docs/plan-role-superviseur.md §3).
  static UserRole? fromString(String? role) {
    switch (role?.trim().toLowerCase()) {
      case 'technician':
      case 'technicien':
        return UserRole.technician;
      case 'admin':
        return UserRole.admin;
      case 'supervisor':
        return UserRole.supervisor;
      default:
        return null;
    }
  }
}
