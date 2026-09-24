import 'package:novadis_cri/models/user_role.dart';

/// Capacités de l'application — miroir exact de
/// `backend/src/NovadisApi/Authorization/Capabilities.cs` (mêmes noms, même
/// matrice). L'API reste seule garante des droits : ici on ne fait que masquer
/// ce qu'elle refuserait.
///
/// Ne jamais tester un rôle directement (`role == 'Admin'`) : utiliser
/// `permissionsProvider.hasPermission(Permission.x)`.
class Permission {
  /// Créer / modifier ses CRI, signature client, photos.
  static const String criCreate = 'CriCreate';

  /// Lire les CRI de tous les techniciens (sinon : les siens).
  static const String criReadAll = 'CriReadAll';

  /// Modifier les brouillons et supprimer les CRI d'autrui.
  static const String criManageAny = 'CriManageAny';

  /// Statistiques personnelles.
  static const String personalStats = 'PersonalStats';

  /// Statistiques globales et tableaux de bord.
  static const String globalStats = 'GlobalStats';

  /// Exports portant sur tous les techniciens.
  static const String exportAll = 'ExportAll';

  /// Voir les documents exportés par tous.
  static const String documentsReadAll = 'DocumentsReadAll';

  /// Renommer / supprimer / partager les documents d'autrui.
  static const String documentsManageAny = 'DocumentsManageAny';

  /// Administration technique : import des sites, santé de l'API.
  static const String systemAdmin = 'SystemAdmin';
}

/// Matrice rôle → capacités (docs/plan-role-superviseur.md §4).
const Map<UserRole, Set<String>> rolePermissions = {
  UserRole.technician: {
    Permission.criCreate,
    Permission.personalStats,
  },
  UserRole.admin: {
    Permission.criCreate,
    Permission.criReadAll,
    Permission.criManageAny,
    Permission.personalStats,
    Permission.globalStats,
    Permission.exportAll,
    Permission.documentsReadAll,
    Permission.documentsManageAny,
    Permission.systemAdmin,
  },
  UserRole.supervisor: {},
};
