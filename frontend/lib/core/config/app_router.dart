import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:novadis_cri/core/constants/permissions.dart';
import 'package:novadis_cri/core/storage/storage_service.dart';
import 'package:novadis_cri/features/auth/presentation/providers/permissions_provider.dart';
import 'package:novadis_cri/features/auth/login_screen.dart';
import 'package:novadis_cri/features/auth/otp_verification_screen.dart';
import 'package:novadis_cri/screens/role_home_screen.dart';
import 'package:novadis_cri/features/dashboard/pages/main_dashboard_page.dart';
import 'package:novadis_cri/features/dashboard/pages/site_dashboard_page.dart';
import 'package:novadis_cri/features/dashboard/pages/technician_dashboard_page.dart';
import 'package:novadis_cri/features/cri_form/cri_form_screen.dart';
import 'package:novadis_cri/features/cri_form/pages/cri_projet_form_page.dart';
import 'package:novadis_cri/features/cri_form/pages/cri_service_form_page.dart';
import 'package:novadis_cri/features/history/history_screen.dart';
import 'package:novadis_cri/features/admin/admin_screen.dart';
import 'package:novadis_cri/features/documents/pages/documents_page.dart';
import 'package:novadis_cri/features/documents/pages/cri_selection_page.dart';

/// Configuration du routeur de l'application
/// Utilise GoRouter pour la navigation
class AppRouter {
  static const String login = '/login';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String siteDashboard = '/dashboard/site/:siteId';
  static const String technicianDashboard = '/dashboard/technician/:techId';
  static const String criForm = '/cri-form';
  static const String criNewProjet = '/cri/new/projet';
  static const String criNewService = '/cri/new/service';
  static const String criEdit = '/cri/edit/:id';
  static const String criView = '/cri/view/:id';
  static const String history = '/history';
  static const String documents = '/documents';
  static const String criSelection = '/documents/selection';
  static const String admin = '/admin';
  static const String verifyOtp = '/verify-otp';

  /// Global navigator key — used by Dio interceptor to redirect on auth failure
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Permission requise pour ouvrir [location], `null` si la route est libre.
  /// Filet d'UX seulement : c'est l'API qui refuse réellement l'action.
  static String? requiredPermission(String location) {
    if (location == criForm ||
        location.startsWith('/cri/new/') ||
        location.startsWith('/cri/edit/') ||
        location.startsWith('/cri/view/')) {
      // /cri/view ouvre aujourd'hui le formulaire d'édition.
      return Permission.criCreate;
    }
    if (location.startsWith('/dashboard/site/') ||
        location.startsWith('/dashboard/technician/')) {
      return Permission.globalStats;
    }
    return null;
  }

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: login,
    redirect: (context, state) async {
      final permission = requiredPermission(state.matchedLocation);
      if (permission == null) return null;
      final role = await StorageService().getUserRole();
      return PermissionsService(role).hasPermission(permission) ? null : home;
    },
    routes: [
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: verifyOtp,
        name: 'verify-otp',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return OtpVerificationScreen(email: email);
        },
      ),
      // ─── Page d'accueil basée sur le rôle ───
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const RoleHomeScreen(),
      ),
      GoRoute(
        path: dashboard,
        name: 'dashboard',
        builder: (context, state) => const MainDashboardPage(),
      ),
      // Dashboard Site
      GoRoute(
        path: siteDashboard,
        name: 'site-dashboard',
        builder: (context, state) {
          final siteId = state.pathParameters['siteId'] ?? '';
          return SiteDashboardPage(siteId: siteId);
        },
      ),
      // Dashboard Technicien
      GoRoute(
        path: technicianDashboard,
        name: 'technician-dashboard',
        builder: (context, state) {
          final techId = state.pathParameters['techId'] ?? '';
          return TechnicianDashboardPage(technicianId: techId);
        },
      ),
      GoRoute(
        path: criForm,
        name: 'cri-form',
        builder: (context, state) => const CriFormScreen(),
      ),
      // Nouveau CRI Projet
      GoRoute(
        path: criNewProjet,
        name: 'cri-new-projet',
        builder: (context, state) => const CriProjetFormPage(),
      ),
      // Nouveau CRI Service
      GoRoute(
        path: criNewService,
        name: 'cri-new-service',
        builder: (context, state) => const CriServiceFormPage(),
      ),
      // Éditer un CRI (détecte le type automatiquement)
      GoRoute(
        path: criEdit,
        name: 'cri-edit',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          final type = state.uri.queryParameters['type'];

          if (type == 'projet') {
            return CriProjetFormPage(criId: id);
          } else {
            return CriServiceFormPage(criId: id);
          }
        },
      ),
      // Visualiser un CRI (lecture seule)
      GoRoute(
        path: criView,
        name: 'cri-view',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          final type = state.uri.queryParameters['type'];

          // TODO: Implémenter une vue lecture seule
          // Pour l'instant, redirige vers l'écran d'édition
          if (type == 'projet') {
            return CriProjetFormPage(criId: id);
          } else {
            return CriServiceFormPage(criId: id);
          }
        },
      ),
      GoRoute(
        path: history,
        name: 'history',
        builder: (context, state) => HistoryScreen(
          siteFilter: state.uri.queryParameters['site'],
        ),
      ),
      GoRoute(
        path: documents,
        name: 'documents',
        builder: (context, state) => const DocumentsPage(),
      ),
      GoRoute(
        path: criSelection,
        name: 'cri-selection',
        builder: (context, state) {
          final extra = state.extra;
          final format =
              extra is CriExportFormat ? extra : CriExportFormat.pdf;
          return CriSelectionPage(format: format);
        },
      ),
      GoRoute(
        path: admin,
        name: 'admin',
        builder: (context, state) => const AdminScreen(),
      ),
    ],
  );
}
