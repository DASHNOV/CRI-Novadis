import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/features/dashboard/models/stats_query.dart';
import 'package:novadis_cri/features/dashboard/providers/dashboard_providers.dart';
import 'package:novadis_cri/features/dashboard/views/general_view.dart';
import 'package:novadis_cri/features/dashboard/widgets/dashboard_cards.dart';
import 'package:novadis_cri/features/dashboard/widgets/searchable_sorted_list.dart';
import 'package:novadis_cri/features/dashboard/widgets/site_stats_widgets.dart';
import 'package:novadis_cri/models/site_stats.dart';

/// Onglet « Sites » : classement, répartition (équipe) et liste filtrable.
class SitesView extends ConsumerWidget {
  final StatsQuery query;
  final bool isGlobal;

  const SitesView({super.key, required this.query, required this.isGlobal});

  static final Map<String, Comparator<SiteStats>> sorts = {
    'Nombre de CRI': (a, b) => b.totalInterventions.compareTo(a.totalInterventions),
    'Taux de récurrence': (a, b) => b.tauxRecurrence.compareTo(a.tauxRecurrence),
    'Durée moyenne': (a, b) =>
        (b.dureeMoyenneMinutes ?? -1).compareTo(a.dureeMoyenneMinutes ?? -1),
    'Dernière intervention': (a, b) => (b.derniereIntervention ?? DateTime(0))
        .compareTo(a.derniereIntervention ?? DateTime(0)),
    'Nom (A → Z)': (a, b) =>
        a.siteNom.toLowerCase().compareTo(b.siteNom.toLowerCase()),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistiques par site',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppTheme.space12),
        TopSitesChart(query: query),
        const SizedBox(height: AppTheme.space16),
        if (isGlobal) ...[
          RequestTypesPie(query: query),
          const SizedBox(height: AppTheme.space16),
        ],
        ref.watch(siteStatsProvider(query)).when(
              data: (sites) => SearchableSortedList<SiteStats>(
                items: sites,
                searchHint: 'Rechercher un site, un client, une ville…',
                searchText: (s) => '${s.siteNom} ${s.clientNom ?? ''} ${s.ville ?? ''}',
                sorts: sorts,
                emptyMessage: 'Aucun site sur cette période',
                itemBuilder: (site) => SiteStatsCard(
                  key: ValueKey(site.siteNom),
                  site: site,
                  onTap: isGlobal ? () => openSiteDashboard(context, site) : null,
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
                  onRetry: () => ref.invalidate(siteStatsProvider(query)),
                ),
              ),
            ),
      ],
    );
  }
}
