import 'package:flutter_test/flutter_test.dart';
import 'package:novadis_cri/core/constants/permissions.dart';
import 'package:novadis_cri/features/auth/presentation/providers/permissions_provider.dart';
import 'package:novadis_cri/models/user_role.dart';

void main() {
  group('UserRole.fromString', () {
    test('reconnaît les valeurs canoniques et la forme héritée', () {
      expect(UserRole.fromString('Technician'), UserRole.technician);
      expect(UserRole.fromString('Technicien'), UserRole.technician);
      expect(UserRole.fromString('Admin'), UserRole.admin);
      expect(UserRole.fromString('Supervisor'), UserRole.supervisor);
    });

    test('rôle inconnu ou absent → null, jamais technicien', () {
      expect(UserRole.fromString('Hyperviseur'), isNull);
      expect(UserRole.fromString(''), isNull);
      expect(UserRole.fromString(null), isNull);
    });
  });

  group('PermissionsService', () {
    test('rôle inconnu → aucune permission', () {
      final service = PermissionsService('Hyperviseur');
      expect(service.role, isNull);
      expect(service.hasPermission(Permission.criCreate), isFalse);
    });

    test('rôle absent → aucune permission', () {
      final service = PermissionsService(null);
      expect(service.hasPermission(Permission.criCreate), isFalse);
      expect(service.hasPermission(Permission.personalStats), isFalse);
    });

    test('technicien : crée des CRI, ne voit pas ceux des autres', () {
      final service = PermissionsService('Technician');
      expect(service.hasPermission(Permission.criCreate), isTrue);
      expect(service.hasPermission(Permission.criReadAll), isFalse);
      expect(service.hasPermission(Permission.criManageAny), isFalse);
    });

    test('admin : toutes les capacités', () {
      final service = PermissionsService('Admin');
      for (final p in rolePermissions[UserRole.admin]!) {
        expect(service.hasPermission(p), isTrue, reason: p);
      }
    });
  });
}
