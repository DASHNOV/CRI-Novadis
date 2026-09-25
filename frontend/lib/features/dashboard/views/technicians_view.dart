import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/features/dashboard/models/stats_query.dart';
import 'package:novadis_cri/features/dashboard/providers/dashboard_providers.dart';
import 'package:novadis_cri/features/dashboard/views/general_view.dart';
import 'package:novadis_cri/features/dashboard/widgets/dashboard_cards.dart';
import 'package:novadis_cri/features/dashboard/widgets/searchable_sorted_list.dart';
import 'package:novadis_cri/features/dashboard/widgets/technician_stats_widgets.dart';
import 'package:novadis_cri/models/technician_detailed_stats.dart';

/// Onglet « Techniciens » (périmètre équipe) : répartition par site et liste filtrable.
class TechniciansView extends ConsumerWidget {
  final StatsQuery query;

  const TechniciansView({super.key, required this.query});

  static final Map<String, Comparator<TechnicianDetailedStats>> sorts = {
    'Nombre de CRI': (a, b) => b.totalInterventions.compareTo(a.totalInterventions),
    'Heures': (a, b) => b.totalHeures.compareTo(a.totalHeures),
    'Durée moyenne': (a, b) =>
        (b.dureeMoyenneMinutes ?? -1).compareTo(a.dureeMoyenneMinutes ?? -1),
    'Récurrences': (a, b) =>
        b.totalRecurrenceRequise.compareTo(a.totalRecurrenceRequise),
    'Nom (A → Z)': (a, b) =>
        a.nomComplet.toLowerCase().compareTo(b.nomComplet.toLowerCase()),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistiques par technicien',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppTheme.space12),
        TechSiteHeatmap(query: query),
        const SizedBox(height: AppTheme.space16),
        ref.watch(technicianStatsProvider(query)).when(
              data: (techs) => SearchableSortedList<TechnicianDetailedStats>(
                items: techs,
                searchHint: 'Rechercher un technicien…',
                searchText: (t) => t.nomComplet,
                sorts: sorts,
                emptyMessage: 'Aucun technicien actif sur cette période',
                itemBuilder: (tech) => TechnicianStatsCard(
                  key: ValueKey(tech.id),
                  tech: tech,
                  onTap: () => openTechnicianDashboard(context, tech),
                ),
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.space24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => DashboardCard(
                child: DashboardErrorView(
                  error: e,
                  onRetry: () => ref.invalidate(technicianStatsProvider(query)),
                ),
              ),
            ),
      ],
    );
  }
}
