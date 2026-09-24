import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:novadis_cri/core/constants/permissions.dart';
import 'package:novadis_cri/core/providers/main_nav_provider.dart';
import 'package:novadis_cri/core/widgets/responsive_scaffold.dart';
import 'package:novadis_cri/features/auth/presentation/providers/permissions_provider.dart';
import 'package:novadis_cri/models/user_role.dart';
import 'package:novadis_cri/screens/technician/personal_home_screen.dart';
import 'package:novadis_cri/features/cri_form/cri_form_screen.dart';
import 'package:novadis_cri/screens/admin/global_dashboard_screen.dart';
import 'package:novadis_cri/screens/admin/global_history_screen.dart';
import 'package:novadis_cri/features/admin/admin_screen.dart';
import 'package:novadis_cri/features/documents/pages/documents_page.dart';
import 'package:novadis_cri/services/sync_service.dart';

/// Un onglet de l'espace de gestion, visible seulement si l'utilisateur a
/// [permission] (`null` = toujours visible).
class _MainTab {
  final NavDestination destination;
  final Widget screen;
  final String? permission;

  const _MainTab(this.destination, this.screen, [this.permission]);
}

const String _defaultTab = 'Vue Globale';

const List<_MainTab> _allTabs = [
  _MainTab(
    NavDestination(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Accueil',
    ),
    PersonalHomeScreen(),
    Permission.personalStats,
  ),
  _MainTab(
    NavDestination(
      icon: Icon(Icons.add_circle_outline),
      activeIcon: Icon(Icons.add_circle),
      label: 'Nouveau CRI',
    ),
    CriFormScreen(),
    Permission.criCreate,
  ),
  _MainTab(
    NavDestination(
      icon: Icon(Icons.dashboard_outlined),
      activeIcon: Icon(Icons.dashboard),
      label: _defaultTab,
    ),
    GlobalDashboardScreen(),
    Permission.globalStats,
  ),
  _MainTab(
    NavDestination(
      icon: Icon(Icons.list_alt_outlined),
      activeIcon: Icon(Icons.list_alt),
      label: 'Tous les CRI',
    ),
    GlobalHistoryScreen(),
    Permission.criReadAll,
  ),
  _MainTab(
    NavDestination(
      icon: Icon(Icons.folder_outlined),
      activeIcon: Icon(Icons.folder),
      label: 'Documents',
    ),
    DocumentsPage(),
  ),
  _MainTab(
    NavDestination(
      icon: Icon(Icons.settings_outlined),
      activeIcon: Icon(Icons.settings),
      label: 'Paramètres',
    ),
    AdminScreen(),
  ),
];

/// Espace de gestion, commun aux administrateurs et aux superviseurs : les
/// onglets affichés dépendent des permissions (un superviseur n'a ni
/// « Accueil » personnel ni « Nouveau CRI »).
class AdminMainScreen extends ConsumerStatefulWidget {
  /// Rôle déjà résolu par [RoleHomeScreen] : `userRoleProvider` se charge de
  /// façon asynchrone et peut encore être vide au premier affichage.
  final UserRole role;

  const AdminMainScreen({super.key, required this.role});

  @override
  ConsumerState<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends ConsumerState<AdminMainScreen> {
  late final List<_MainTab> _tabs;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    final permissions = PermissionsService(widget.role.apiValue);
    _tabs = [
      for (final tab in _allTabs)
        if (tab.permission == null || permissions.hasPermission(tab.permission!))
          tab,
    ];
    _currentIndex = _indexOf(_defaultTab);

    // Repousse les CRI soumis hors ligne (démarrage + retour de connectivité).
    // Inutile sans droit de création : aucun CRI local à synchroniser.
    if (permissions.hasPermission(Permission.criCreate)) {
      ref.read(syncServiceProvider).start();
    }
  }

  /// Index de l'onglet [label], ou le premier onglet s'il n'est pas affiché
  /// pour ce rôle (ex. « Accueil » demandé depuis Documents par un superviseur).
  int _indexOf(String label) {
    final index = _tabs.indexWhere((t) => t.destination.label == label);
    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(requestedMainTabProvider, (previous, next) {
      if (next == null) return;
      final index = _indexOf(next);
      if (index != _currentIndex) {
        setState(() => _currentIndex = index);
      }
      ref.read(requestedMainTabProvider.notifier).state = null;
    });

    return ResponsiveScaffold(
      currentIndex: _currentIndex,
      onIndexChanged: (index) => setState(() => _currentIndex = index),
      destinations: [for (final t in _tabs) t.destination],
      screens: [for (final t in _tabs) t.screen],
    );
  }
}
