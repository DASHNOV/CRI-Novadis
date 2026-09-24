/// Rôles utilisateur
class UserRole {
  static const String admin = 'Admin';
  static const String technicien = 'Technician';
}

/// Permissions disponibles
class Permission {
  // CRI permissions
  static const String viewOwnCris = 'view_own_cris';
  static const String viewAllCris = 'view_all_cris';
  static const String createCri = 'create_cri';
  static const String editOwnCri = 'edit_own_cri';
  static const String editAnyCri = 'edit_any_cri';
  static const String deleteOwnCri = 'delete_own_cri';
  static const String deleteAnyCri = 'delete_any_cri';
  static const String signCri = 'sign_cri';
  static const String addPhotos = 'add_photos';

  // Stats & Dashboard
  static const String viewPersonalStats = 'view_personal_stats';
  static const String viewGlobalDashboard = 'view_global_dashboard';

  // Admin features
  static const String manageUsers = 'manage_users';
  static const String exportData = 'export_data';
  static const String manageReferences = 'manage_references';
}

/// Mapping des permissions par rôle
const Map<String, Set<String>> rolePermissions = {
  UserRole.technicien: {
    Permission.viewOwnCris,
    Permission.createCri,
    Permission.editOwnCri,
    Permission.deleteOwnCri,
    Permission.viewPersonalStats,
    Permission.addPhotos,
    Permission.signCri,
  },
  UserRole.admin: {
    Permission.viewOwnCris,
    Permission.createCri,
    Permission.editOwnCri,
    Permission.viewPersonalStats,
    Permission.viewAllCris,
    Permission.editAnyCri,
    Permission.deleteAnyCri,
    Permission.viewGlobalDashboard,
    Permission.manageUsers,
    Permission.exportData,
    Permission.manageReferences,
  },
};
