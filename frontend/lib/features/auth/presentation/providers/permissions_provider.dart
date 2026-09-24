import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novadis_cri/core/constants/permissions.dart';
import 'package:novadis_cri/core/storage/storage_service.dart';

// Provides the current user role
final userRoleProvider = StateNotifierProvider<UserRoleNotifier, String?>((
  ref,
) {
  return UserRoleNotifier(ref.read(storageServiceProvider));
});

class UserRoleNotifier extends StateNotifier<String?> {
  final StorageService _storage;

  UserRoleNotifier(this._storage) : super(null) {
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await _storage.getUserRole();
    state = role;
  }

  Future<void> refresh() async {
    await _loadRole();
  }
}

// Provides the current user ID (for ownership checks)
final userIdProvider = StateNotifierProvider<UserIdNotifier, String?>((ref) {
  return UserIdNotifier(ref.read(storageServiceProvider));
});

class UserIdNotifier extends StateNotifier<String?> {
  final StorageService _storage;

  UserIdNotifier(this._storage) : super(null) {
    _load();
  }

  Future<void> _load() async {
    state = await _storage.getUserId();
  }

  Future<void> refresh() async => _load();
}

// Provides helper to check permissions
final permissionsProvider = Provider<PermissionsService>((ref) {
  final role = ref.watch(userRoleProvider);
  return PermissionsService(role);
});

class PermissionsService {
  final String? _role;

  PermissionsService(this._role);

  bool hasPermission(String permission) {
    if (_role == null) return false;
    // L'API renvoie la forme canonique ('Technician'), mais un rôle stocké
    // avant la normalisation peut encore valoir 'Technicien'.
    final key = _role.toLowerCase() == 'technicien' ? UserRole.technicien : _role;
    final permissions = rolePermissions[key];
    return permissions != null && permissions.contains(permission);
  }

  String? get role => _role;
}
