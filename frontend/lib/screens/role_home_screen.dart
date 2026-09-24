import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:novadis_cri/core/config/app_router.dart';
import 'package:novadis_cri/core/storage/storage_service.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/features/auth/data/auth_service.dart';
import 'package:novadis_cri/models/user_role.dart';
import 'package:novadis_cri/screens/technician/technician_main_screen.dart';
import 'package:novadis_cri/screens/admin/admin_main_screen.dart';
import 'package:novadis_cri/core/theme/theme_provider.dart';

/// Écran pivot qui détermine l'interface à afficher selon le rôle utilisateur.
/// Lit le rôle depuis le StorageService et redirige vers l'écran approprié.
class RoleHomeScreen extends ConsumerStatefulWidget {
  const RoleHomeScreen({super.key});

  @override
  ConsumerState<RoleHomeScreen> createState() => _RoleHomeScreenState();
}

class _RoleHomeScreenState extends ConsumerState<RoleHomeScreen> {
  UserRole? _role;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final storage = ref.read(storageServiceProvider);
    final roleStr = await storage.getUserRole();

    if (mounted) {
      setState(() {
        // Rôle absent ou inconnu → null : jamais de repli sur technicien.
        _role = UserRole.fromString(roleStr);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeAnimationProvider);
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement de votre espace...'),
            ],
          ),
        ),
      );
    }

    return switch (_role) {
      UserRole.admin || UserRole.supervisor => AdminMainScreen(role: _role!),
      UserRole.technician => const TechnicianMainScreen(),
      null => const _UnsupportedRoleScreen(),
    };
  }
}

/// Rôle absent ou non géré par cette version de l'application : aucun espace
/// n'est ouvert, l'utilisateur ne peut que se déconnecter.
class _UnsupportedRoleScreen extends ConsumerWidget {
  const _UnsupportedRoleScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 56, color: AppTheme.textTertiary),
              const SizedBox(height: AppTheme.space16),
              const Text(
                'Rôle non pris en charge',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppTheme.space8),
              Text(
                'Votre compte n\'a pas de rôle reconnu par cette version de '
                'l\'application. Contactez un administrateur.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: AppTheme.space24),
              FilledButton.icon(
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Se déconnecter'),
                onPressed: () async {
                  await ref.read(authServiceProvider).logout();
                  if (context.mounted) context.go(AppRouter.login);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
