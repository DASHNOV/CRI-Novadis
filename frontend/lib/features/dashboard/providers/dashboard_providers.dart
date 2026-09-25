import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:novadis_cri/core/constants/permissions.dart';
import 'package:novadis_cri/features/auth/presentation/providers/permissions_provider.dart';
import 'package:novadis_cri/features/dashboard/models/dashboard_models.dart';
import 'package:novadis_cri/features/dashboard/models/stats_query.dart';
import 'package:novadis_cri/services/stats_api_service.dart';
import 'package:novadis_cri/models/global_stats.dart';
import 'package:novadis_cri/models/site_stats.dart';
import 'package:novadis_cri/models/technician_detailed_stats.dart';
import 'package:novadis_cri/models/distribution_stats.dart';
import 'package:novadis_cri/models/dashboard_evolution.dart';
import 'package:novadis_cri/models/recent_intervention.dart';

// Toutes les données du dashboard viennent de l'API : aucun calcul local.
// Un même écran sert deux périmètres (cf. [dashboardIsGlobalProvider]).

/// Provider pour la période sélectionnée
final selectedPeriodProvider =
    StateNotifierProvider<SelectedPeriodNotifier, DashboardPeriod>((ref) {
      return SelectedPeriodNotifier();
    });

/// Notifier pour la période sélectionnée avec persistence
class SelectedPeriodNotifier extends StateNotifier<DashboardPeriod> {
  SelectedPeriodNotifier() : super(DashboardPeriod.month) {
    _loadSavedPeriod();
  }

  Future<void> _loadSavedPeriod() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPeriod = prefs.getString('dashboard_period');
      if (savedPeriod != null) {
        state = DashboardPeriod.values.firstWhere(
          (p) => p.name == savedPeriod,
          orElse: () => DashboardPeriod.month,
        );
      }
    } catch (e) {
      // Ignore si erreur de chargement
    }
  }

  Future<void> setPeriod(DashboardPeriod period) async {
    state = period;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dashboard_period', period.name);
    } catch (e) {
      // Ignore si erreur de sauvegarde
    }
  }
}

/// Mode de vue du dashboard
enum DashboardViewMode { general, parSite, parTechnicien }

/// Provider pour le mode de vue
final dashboardViewModeProvider = StateProvider<DashboardViewMode>(
  (ref) => DashboardViewMode.general,
);

/// `true` : statistiques de toute l'équipe (`/api/global`) ;
/// `false` : dashboard personnel (`/api/personal/dashboard`, ses propres CRI).
final dashboardIsGlobalProvider = Provider<bool>((ref) {
  return ref.watch(permissionsProvider).hasPermission(Permission.globalStats);
});

/// Périmètre du dashboard principal : la période sélectionnée.
final dashboardQueryProvider = Provider<StatsQuery>((ref) {
  return StatsQuery(periodDays: ref.watch(selectedPeriodProvider).days);
});

/// KPI du périmètre.
final dashboardStatsProvider = FutureProvider.autoDispose
    .family<GlobalStats, StatsQuery>((ref, query) {
      return ref
          .watch(statsApiServiceProvider)
          .getDashboardStats(query, global: ref.watch(dashboardIsGlobalProvider));
    });

/// Statistiques par site.
final siteStatsProvider = FutureProvider.autoDispose
    .family<List<SiteStats>, StatsQuery>((ref, query) {
      return ref
          .watch(statsApiServiceProvider)
          .getStatsBySite(query, global: ref.watch(dashboardIsGlobalProvider));
    });

/// Courbe d'évolution.
final evolutionProvider = FutureProvider.autoDispose
    .family<DashboardEvolution, StatsQuery>((ref, query) {
      return ref
          .watch(statsApiServiceProvider)
          .getEvolution(query, global: ref.watch(dashboardIsGlobalProvider));
    });

/// Dernières interventions : `(query, limit)`.
final recentInterventionsProvider = FutureProvider.autoDispose
    .family<List<RecentIntervention>, ({StatsQuery query, int limit})>((
      ref,
      args,
    ) {
      return ref
          .watch(statsApiServiceProvider)
          .getRecentInterventions(
            args.query,
            global: ref.watch(dashboardIsGlobalProvider),
            limit: args.limit,
          );
    });

/// Statistiques par technicien (global uniquement).
final technicianStatsProvider = FutureProvider.autoDispose
    .family<List<TechnicianDetailedStats>, StatsQuery>((ref, query) {
      return ref.watch(statsApiServiceProvider).getStatsByTechnician(query);
    });

/// Statistiques croisées (global uniquement).
final distributionStatsProvider = FutureProvider.autoDispose
    .family<DistributionStats, StatsQuery>((ref, query) {
      return ref.watch(statsApiServiceProvider).getDistributionStats(query);
    });

/// Techniciens (global uniquement) : identité pour l'en-tête des pages technicien.
final techniciansProvider = FutureProvider.autoDispose<List<TechnicianModel>>((
  ref,
) async {
  final users = await ref.watch(statsApiServiceProvider).getTechnicians();
  return users.map(TechnicianModel.fromJson).toList();
});

/// Extension pour faciliter le rafraîchissement des données
extension DashboardRefX on WidgetRef {
  void refreshDashboard() {
    invalidate(dashboardStatsProvider);
    invalidate(siteStatsProvider);
    invalidate(evolutionProvider);
    invalidate(recentInterventionsProvider);
    invalidate(technicianStatsProvider);
    invalidate(distributionStatsProvider);
    invalidate(techniciansProvider);
  }
}
