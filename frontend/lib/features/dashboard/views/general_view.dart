import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:novadis_cri/core/config/app_router.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/core/theme/responsive.dart';
import 'package:novadis_cri/core/utils/duration_format.dart';
import 'package:novadis_cri/features/dashboard/config/chart_config.dart';
import 'package:novadis_cri/features/dashboard/models/stats_query.dart';
import 'package:novadis_cri/features/dashboard/providers/dashboard_providers.dart';
import 'package:novadis_cri/features/dashboard/widgets/admin_request_types_pie_widget.dart';
import 'package:novadis_cri/features/dashboard/widgets/admin_technician_site_heatmap_widget.dart';
import 'package:novadis_cri/features/dashboard/widgets/admin_top_sites_chart_widget.dart';
import 'package:novadis_cri/features/dashboard/widgets/dashboard_cards.dart';
import 'package:novadis_cri/features/dashboard/widgets/intervention_list_item.dart';
import 'package:novadis_cri/features/dashboard/widgets/kpi_card_widget.dart';
import 'package:novadis_cri/features/dashboard/widgets/site_stats_widgets.dart';
import 'package:novadis_cri/features/dashboard/widgets/technician_stats_widgets.dart';
import 'package:novadis_cri/features/dashboard/widgets/time_evolution_chart_widget.dart';

/// Onglet « Général » : KPI, courbe, synthèses. [isGlobal] ajoute les blocs
/// propres à l'équipe (répartitions, techniciens).
class GeneralView extends StatelessWidget {
  final StatsQuery query;
  final bool isGlobal;

  const GeneralView({super.key, required this.query, required this.isGlobal});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= Responsive.tablet;
        const gap = SizedBox(width: AppTheme.space24, height: AppTheme.space24);

        Widget pair(Widget left, Widget right) => isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Expanded(child: left), gap, Expanded(child: right)],
              )
            : Column(children: [left, const SizedBox(height: AppTheme.space16), right]);

        final spacing = SizedBox(height: isDesktop ? AppTheme.space24 : AppTheme.space16);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardKpis(query: query),
            spacing,
            pair(EvolutionCard(query: query), TopSitesSummary(query: query, isGlobal: isGlobal)),
            spacing,
            if (isGlobal) ...[
              pair(TopSitesChart(query: query), RequestTypesPie(query: query)),
              spacing,
              TechSiteHeatmap(query: query),
              spacing,
              pair(
                TechniciansSummary(query: query),
                RecentInterventionsSummary(query: query, isGlobal: isGlobal),
              ),
            ] else
              RecentInterventionsSummary(query: query, isGlobal: isGlobal),
          ],
        );
      },
    );
  }
}

/// KPI du périmètre, avec la variation par rapport à la période précédente.
class DashboardKpis extends ConsumerWidget {
  final StatsQuery query;
  const DashboardKpis({super.key, required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(dashboardStatsProvider(query)).when(
          data: (stats) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KpiGrid(
                cards: [
                  KpiCard(
                    title: 'Interventions',
                    value: stats.totalInterventions.toString(),
                    icon: Icons.assignment,
                    iconColor: ChartConfig.kpiColors['interventions']!,
                    subtitle: 'Total sur la période',
                    trendValue: stats.interventionsTrend,
                  ),
                  KpiCard(
                    title: 'Résolues',
                    value: stats.totalResolu.toString(),
                    icon: Icons.check_circle,
                    iconColor: const Color(0xFF10B981),
                    subtitle: 'CRI résolus',
                    trendValue: stats.resoluTrend,
                  ),
                  KpiCard(
                    title: 'Durée moy.',
                    value: stats.dureeMoyenneFormatee,
                    icon: Icons.timer,
                    iconColor: const Color(0xFF6366F1),
                    subtitle: 'Par intervention',
                  ),
                  KpiCard(
                    title: 'Récurrences',
                    value: stats.totalRecurrenceRequise.toString(),
                    icon: Icons.replay,
                    iconColor: AppTheme.error,
                    subtitle: 'Retours nécessaires',
                    trendValue: stats.recurrenceTrend,
                    // Plus de retours sur site : mauvaise nouvelle.
                    trendPositive: stats.recurrenceTrend == null
                        ? null
                        : stats.recurrenceTrend! < 0,
                  ),
                ],
              ),
              if (stats.periodePrecedente != null) ...[
                const SizedBox(height: AppTheme.space8),
                Text(
                  'Flèches : évolution par rapport à la période précédente de même durée.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textTertiary),
                ),
              ],
            ],
          ),
          loading: () => KpiGrid(
            cards: List.generate(
              4,
              (index) => KpiCard(
                title: '',
                value: '',
                icon: Icons.help,
                iconColor: AppTheme.textTertiary,
                isLoading: true,
              ),
            ),
          ),
          error: (e, _) => DashboardCard(
            child: DashboardErrorView(
              error: e,
              onRetry: () => ref.invalidate(dashboardStatsProvider(query)),
            ),
          ),
        );
  }
}

class EvolutionCard extends ConsumerWidget {
  final StatsQuery query;
  const EvolutionCard({super.key, required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(evolutionProvider(query)).when(
          data: (evolution) => TimeEvolutionChartWidget(
            data: evolution.points,
            title: 'Évolution de l\'activité',
            subtitle: 'Interventions ${evolution.granularityLabel}',
          ),
          loading: () => const DashboardLoadingCard(),
          error: (e, _) => DashboardCard(
            child: DashboardErrorView(
              error: e,
              onRetry: () => ref.invalidate(evolutionProvider(query)),
            ),
          ),
        );
  }
}

class TopSitesChart extends ConsumerWidget {
  final StatsQuery query;
  const TopSitesChart({super.key, required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(siteStatsProvider(query)).when(
          data: (sites) => AdminTopSitesChartWidget(
            sites: sites,
            subtitle: 'Classement des sites les plus sollicités',
          ),
          loading: () => const DashboardLoadingCard(),
          error: (e, _) => DashboardCard(
            child: DashboardErrorView(
              error: e,
              onRetry: () => ref.invalidate(siteStatsProvider(query)),
            ),
          ),
        );
  }
}

class RequestTypesPie extends ConsumerWidget {
  final StatsQuery query;
  const RequestTypesPie({super.key, required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(distributionStatsProvider(query)).when(
          data: (dist) => AdminRequestTypesPieWidget(
            distribution: dist.repartitionParCategorie ?? const {},
            subtitle: 'Répartition par catégorie',
          ),
          loading: () => const DashboardLoadingCard(),
          error: (e, _) => DashboardCard(
            child: DashboardErrorView(
              error: e,
              onRetry: () => ref.invalidate(distributionStatsProvider(query)),
            ),
          ),
        );
  }
}

class TechSiteHeatmap extends ConsumerWidget {
  final StatsQuery query;
  const TechSiteHeatmap({super.key, required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(distributionStatsProvider(query)).when(
          data: (dist) => AdminTechnicianSiteHeatmapWidget(
            entries: dist.technicienParSite ?? const [],
          ),
          loading: () => const DashboardLoadingCard(),
          error: (e, _) => DashboardCard(
            child: DashboardErrorView(
              error: e,
              onRetry: () => ref.invalidate(distributionStatsProvider(query)),
            ),
          ),
        );
  }
}

class TopSitesSummary extends ConsumerWidget {
  final StatsQuery query;
  final bool isGlobal;
  const TopSitesSummary({super.key, required this.query, required this.isGlobal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardSectionCard(
      title: 'Sites les plus actifs',
      actionLabel: 'Voir tous',
      onAction: () => ref
          .read(dashboardViewModeProvider.notifier)
          .setMode(DashboardViewMode.parSite),
      child: ref.watch(siteStatsProvider(query)).when(
            data: (sites) {
              if (sites.isEmpty) {
                return const DashboardEmptyMessage('Aucune donnée de site');
              }
              return Column(
                children: sites
                    .take(3)
                    .map((site) => SiteListTile(
                          site: site,
                          // Page site : périmètre équipe uniquement.
                          onTap: isGlobal ? () => openSiteDashboard(context, site) : null,
                        ))
                    .toList(),
              );
            },
            loading: () => const DashboardLinearLoading(),
            error: (e, _) => DashboardErrorView(
              error: e,
              onRetry: () => ref.invalidate(siteStatsProvider(query)),
            ),
          ),
    );
  }
}

class TechniciansSummary extends ConsumerWidget {
  final StatsQuery query;
  const TechniciansSummary({super.key, required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardSectionCard(
      title: 'Répartition techniciens',
      actionLabel: 'Détails',
      onAction: () => ref
          .read(dashboardViewModeProvider.notifier)
          .setMode(DashboardViewMode.parTechnicien),
      child: ref.watch(technicianStatsProvider(query)).when(
            data: (techs) {
              if (techs.isEmpty) {
                return const DashboardEmptyMessage('Aucun technicien actif');
              }
              return Column(
                children: techs
                    .take(3)
                    .map((tech) => TechnicianListTile(
                          tech: tech,
                          onTap: () => openTechnicianDashboard(context, tech),
                        ))
                    .toList(),
              );
            },
            loading: () => const DashboardLinearLoading(),
            error: (e, _) => DashboardErrorView(
              error: e,
              onRetry: () => ref.invalidate(technicianStatsProvider(query)),
            ),
          ),
    );
  }
}

class RecentInterventionsSummary extends ConsumerWidget {
  final StatsQuery query;
  final bool isGlobal;
  const RecentInterventionsSummary({
    super.key,
    required this.query,
    required this.isGlobal,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (query: query, limit: 5);
    return DashboardSectionCard(
      title: 'Interventions Récentes',
      actionLabel: 'Historique',
      onAction: () => context.push(AppRouter.history),
      child: ref.watch(recentInterventionsProvider(args)).when(
            data: (items) {
              if (items.isEmpty) {
                return const DashboardEmptyMessage('Aucune intervention sur la période');
              }
              return Column(
                children: items.map((item) {
                  // Équipe : qui est intervenu ; personnel : où.
                  final who = isGlobal
                      ? item.technicienNom
                      : (item.siteNom ?? item.clientNom);
                  return MobileInterventionListItem(
                    type: item.typeLabel,
                    client: '$who - ${formatDurationMinutes(item.dureeMinutes ?? 0)}',
                    date: item.interventionDate,
                    status: item.statusLabel,
                    onTap: () => context.pushNamed(
                      'cri-view',
                      pathParameters: {'id': item.id},
                      queryParameters: {'type': item.source},
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(AppTheme.space24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => DashboardErrorView(
              error: e,
              onRetry: () => ref.invalidate(recentInterventionsProvider(args)),
            ),
          ),
    );
  }
}
