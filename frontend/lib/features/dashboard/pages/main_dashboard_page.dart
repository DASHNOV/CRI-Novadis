import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:novadis_cri/core/config/app_router.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/core/utils/duration_format.dart';
import 'package:novadis_cri/features/dashboard/config/chart_config.dart';
import 'package:novadis_cri/features/dashboard/models/stats_query.dart';
import 'package:novadis_cri/features/dashboard/providers/dashboard_providers.dart';
import 'package:novadis_cri/features/dashboard/widgets/dashboard_common_widgets.dart';
import 'package:novadis_cri/features/dashboard/widgets/intervention_list_item.dart';
import 'package:novadis_cri/features/dashboard/widgets/kpi_card_widget.dart';
import 'package:novadis_cri/features/dashboard/widgets/time_evolution_chart_widget.dart';
import 'package:novadis_cri/features/dashboard/widgets/admin_top_sites_chart_widget.dart';
import 'package:novadis_cri/features/dashboard/widgets/admin_request_types_pie_widget.dart';
import 'package:novadis_cri/features/dashboard/widgets/admin_technician_site_heatmap_widget.dart';
import 'package:novadis_cri/core/widgets/content_container.dart';
import 'package:novadis_cri/core/theme/responsive.dart';
import 'package:novadis_cri/features/auth/presentation/providers/user_name_provider.dart';
import 'package:novadis_cri/core/theme/theme_provider.dart';
import 'package:novadis_cri/models/site_stats.dart';
import 'package:novadis_cri/models/technician_detailed_stats.dart';
import 'package:intl/intl.dart';

/// Page principale du Dashboard.
///
/// Un seul écran pour deux périmètres ([dashboardIsGlobalProvider]) : l'équipe
/// (Admin, Superviseur) ou ses propres CRI (Technicien). Toutes les données
/// viennent de l'API ; seuls les blocs propres à l'équipe (répartitions,
/// techniciens) sont masqués en périmètre personnel.
class MainDashboardPage extends ConsumerStatefulWidget {
  const MainDashboardPage({super.key});

  @override
  ConsumerState<MainDashboardPage> createState() => _MainDashboardPageState();
}

class _MainDashboardPageState extends ConsumerState<MainDashboardPage> {
  @override
  Widget build(BuildContext context) {
    ref.watch(themeAnimationProvider);
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final viewMode = ref.watch(dashboardViewModeProvider);
    final query = ref.watch(dashboardQueryProvider);
    final isGlobal = ref.watch(dashboardIsGlobalProvider);
    final userName = ref.watch(userNameProvider);
    final isMobile = MediaQuery.of(context).size.width < 640;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ContentContainer(
          maxWidth: 1400,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Modern App Bar
              SliverAppBar(
                floating: true,
                backgroundColor: AppTheme.background,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                leading: isMobile
                    ? null
                    : Container(
                        margin: const EdgeInsets.only(left: AppTheme.space12),
                        child: Icon(
                          Icons.dashboard_rounded,
                          color: AppTheme.textPrimary,
                          size: 24,
                        ),
                      ),
                title: Text(
                  isGlobal ? 'Dashboard Global' : 'Mon activité',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    letterSpacing: -0.3,
                  ),
                ),
                actions: [
                  _buildRefreshButton(),
                  const SizedBox(width: AppTheme.space8),
                ],
              ),

              // Content
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal:
                      Responsive.responsiveHorizontalPadding(context),
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: AppTheme.space16),

                    // Header Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName != null && userName.isNotEmpty
                              ? 'Bonjour $userName,'
                              : 'Bonjour,',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space4),
                        Text(
                          'Vue d\'ensemble',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space16),
                        // Filter Pills (Period)
                        PeriodFilterWidget(
                          selectedPeriod: selectedPeriod,
                          onPeriodChanged: (period) {
                            ref
                                .read(selectedPeriodProvider.notifier)
                                .setPeriod(period);
                          },
                        ),
                        const SizedBox(height: AppTheme.space12),
                        // View Mode Selector
                        _ViewModeSelector(
                          currentMode: viewMode,
                          showTechnicians: isGlobal,
                          onModeChanged: (mode) {
                            ref.read(dashboardViewModeProvider.notifier).state =
                                mode;
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: AppTheme.space24),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth >= 1000;

                        if (viewMode == DashboardViewMode.parSite) {
                          return _buildSitesView(query, isGlobal);
                        }
                        if (viewMode == DashboardViewMode.parTechnicien &&
                            isGlobal) {
                          return _buildTechniciansView(query);
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildKpiSection(query),
                            const SizedBox(height: AppTheme.space24),
                            if (isDesktop)
                              _buildDesktopGeneralView(query, isGlobal)
                            else
                              _buildMobileGeneralView(query, isGlobal),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: AppTheme.space24),
                  ]),
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Container(
      margin: const EdgeInsets.only(right: AppTheme.space4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
      ),
      child: IconButton(
        icon: Icon(Icons.refresh_rounded, color: AppTheme.textSecondary, size: 20),
        onPressed: () => ref.refreshDashboard(),
        tooltip: 'Actualiser',
        splashRadius: 20,
      ),
    );
  }

  // ──────────────────────────────────────────────────
  // Vue Général
  // ──────────────────────────────────────────────────

  Widget _buildKpiSection(StatsQuery query) {
    final statsAsync = ref.watch(dashboardStatsProvider(query));

    return statsAsync.when(
      data: (stats) => KpiGrid(
        cards: [
          KpiCard(
            title: 'Interventions',
            value: stats.totalInterventions.toString(),
            icon: Icons.assignment,
            iconColor: ChartConfig.kpiColors['interventions']!,
            subtitle: 'Total sur la période',
          ),
          KpiCard(
            title: 'Résolues',
            value: stats.totalResolu.toString(),
            icon: Icons.check_circle,
            iconColor: const Color(0xFF10B981),
            subtitle: 'CRI résolus',
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
          ),
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
      error: (e, s) => Text('Erreur: $e'),
    );
  }

  Widget _buildEvolutionChart(StatsQuery query) {
    final evolutionAsync = ref.watch(evolutionProvider(query));
    return evolutionAsync.when(
      data: (evolution) => TimeEvolutionChartWidget(
        data: evolution.points,
        title: 'Évolution de l\'activité',
        subtitle: 'Interventions ${evolution.granularityLabel}',
      ),
      loading: () => _loadingCard(),
      error: (e, s) => Text('Erreur: $e',
          style: const TextStyle(color: AppTheme.error)),
    );
  }

  Widget _buildRecentInterventionsSummary(StatsQuery query, bool isGlobal) {
    final recentAsync =
        ref.watch(recentInterventionsProvider((query: query, limit: 5)));
    return _buildSectionCard(
      title: 'Interventions Récentes',
      actionLabel: 'Historique',
      onAction: () => context.push(AppRouter.history),
      child: recentAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return _emptyMessage('Aucune intervention sur la période');
          }
          return Column(
            children: items.map((item) {
              // Équipe : qui est intervenu ; personnel : où.
              final who = isGlobal
                  ? item.technicienNom
                  : (item.siteNom ?? item.clientNom);
              return MobileInterventionListItem(
                type: item.typeLabel,
                client:
                    '$who - ${formatDurationMinutes(item.dureeMinutes ?? 0)}',
                date: item.interventionDate,
                status: item.statusLabel,
                onTap: () {
                  context.pushNamed(
                    'cri-view',
                    pathParameters: {'id': item.id},
                    queryParameters: {'type': item.source},
                  );
                },
              );
            }).toList(),
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(AppTheme.space24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, s) => Text('Erreur: $e'),
      ),
    );
  }

  Widget _buildDesktopGeneralView(StatsQuery query, bool isGlobal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildEvolutionChart(query)),
            const SizedBox(width: AppTheme.space24),
            Expanded(child: _buildTopSitesSummary(query)),
          ],
        ),
        const SizedBox(height: AppTheme.space24),
        if (isGlobal) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildTopSitesChart(query)),
              const SizedBox(width: AppTheme.space24),
              Expanded(child: _buildRequestTypesPie(query)),
            ],
          ),
          const SizedBox(height: AppTheme.space24),
          _buildTechSiteHeatmap(query),
          const SizedBox(height: AppTheme.space24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildTechWorkloadSummary(query)),
              const SizedBox(width: AppTheme.space24),
              Expanded(child: _buildRecentInterventionsSummary(query, isGlobal)),
            ],
          ),
        ] else
          _buildRecentInterventionsSummary(query, isGlobal),
      ],
    );
  }

  Widget _buildMobileGeneralView(StatsQuery query, bool isGlobal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEvolutionChart(query),
        const SizedBox(height: AppTheme.space16),
        if (isGlobal) ...[
          _buildTopSitesChart(query),
          const SizedBox(height: AppTheme.space16),
          _buildRequestTypesPie(query),
          const SizedBox(height: AppTheme.space16),
          _buildTechSiteHeatmap(query),
          const SizedBox(height: AppTheme.space16),
        ],
        _buildTopSitesSummary(query),
        const SizedBox(height: AppTheme.space16),
        if (isGlobal) ...[
          _buildTechWorkloadSummary(query),
          const SizedBox(height: AppTheme.space16),
        ],
        _buildRecentInterventionsSummary(query, isGlobal),
      ],
    );
  }

  /// Helper to build a consistent section card with title and action
  Widget _buildSectionCard({
    required String title,
    required String actionLabel,
    required VoidCallback onAction,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space16,
              AppTheme.space16,
              AppTheme.space8,
              AppTheme.space8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    letterSpacing: -0.2,
                  ),
                ),
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryContent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space12,
                      vertical: AppTheme.space4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                  child: Text(
                    actionLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: AppTheme.border.withValues(alpha: 0.5),
          ),
          child,
        ],
      ),
    );
  }

  Widget _loadingCard() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _emptyMessage(String message) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.space16),
      child: Text(message, style: TextStyle(color: AppTheme.textTertiary)),
    );
  }

  Widget _linearLoading() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.space16),
      child: LinearProgressIndicator(
        backgroundColor: AppTheme.surfaceVariant,
        valueColor: AlwaysStoppedAnimation(AppTheme.primaryContent),
      ),
    );
  }

  Widget _inlineError(Object e) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.space16),
      child: Text('Erreur: $e',
          style: const TextStyle(color: AppTheme.error, fontSize: 13)),
    );
  }

  Widget _buildTopSitesChart(StatsQuery query) {
    final siteStatsAsync = ref.watch(siteStatsProvider(query));
    return siteStatsAsync.when(
      data: (sites) => AdminTopSitesChartWidget(
        sites: sites,
        subtitle: 'Classement des sites les plus sollicités',
      ),
      loading: () => _loadingCard(),
      error: (e, s) => Text('Erreur: $e',
          style: const TextStyle(color: AppTheme.error)),
    );
  }

  Widget _buildRequestTypesPie(StatsQuery query) {
    final distAsync = ref.watch(distributionStatsProvider(query));
    return distAsync.when(
      data: (dist) => AdminRequestTypesPieWidget(
        distribution: dist.repartitionParCategorie ?? const {},
        subtitle: 'Répartition par catégorie',
      ),
      loading: () => _loadingCard(),
      error: (e, s) => Text('Erreur: $e',
          style: const TextStyle(color: AppTheme.error)),
    );
  }

  Widget _buildTechSiteHeatmap(StatsQuery query) {
    final distAsync = ref.watch(distributionStatsProvider(query));
    return distAsync.when(
      data: (dist) => AdminTechnicianSiteHeatmapWidget(
        entries: dist.technicienParSite ?? const [],
      ),
      loading: () => _loadingCard(),
      error: (e, s) => Text('Erreur: $e',
          style: const TextStyle(color: AppTheme.error)),
    );
  }

  Widget _buildTopSitesSummary(StatsQuery query) {
    final siteStatsAsync = ref.watch(siteStatsProvider(query));

    return _buildSectionCard(
      title: 'Sites les plus actifs',
      actionLabel: 'Voir tous',
      onAction: () => ref.read(dashboardViewModeProvider.notifier).state =
          DashboardViewMode.parSite,
      child: siteStatsAsync.when(
        data: (sites) {
          final top3 = sites.take(3).toList();
          if (top3.isEmpty) return _emptyMessage('Aucune donnée de site');
          return Column(
            children: top3.map((site) => _buildSiteItem(site)).toList(),
          );
        },
        loading: _linearLoading,
        error: (e, s) => _inlineError(e),
      ),
    );
  }

  void _openSite(SiteStats site) {
    // Page site réservée au périmètre équipe (route protégée GlobalStats).
    if (!ref.read(dashboardIsGlobalProvider)) return;
    context.pushNamed(
      'site-dashboard',
      pathParameters: {'siteId': site.siteNom},
    );
  }

  Widget _buildSiteItem(SiteStats site) {
    final clickable = ref.watch(dashboardIsGlobalProvider);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: clickable ? () => _openSite(site) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space16,
            vertical: AppTheme.space12,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.space8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(Icons.location_on_rounded,
                    color: AppTheme.primaryContent, size: 18),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      site.siteNom,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      site.clientNom ?? '-',
                      style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space8, vertical: AppTheme.space4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Text(
                      '${site.totalInterventions} CRI',
                      style: TextStyle(
                        color: AppTheme.primaryContent,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (site.topCategorie != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      site.topCategorie!,
                      style: TextStyle(fontSize: 11, color: AppTheme.textTertiary),
                    ),
                  ],
                ],
              ),
              if (clickable) ...[
                const SizedBox(width: AppTheme.space4),
                Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textTertiary, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTechWorkloadSummary(StatsQuery query) {
    final techStatsAsync = ref.watch(technicianStatsProvider(query));

    return _buildSectionCard(
      title: 'Répartition techniciens',
      actionLabel: 'Détails',
      onAction: () => ref.read(dashboardViewModeProvider.notifier).state =
          DashboardViewMode.parTechnicien,
      child: techStatsAsync.when(
        data: (techs) {
          final top3 = techs.take(3).toList();
          if (top3.isEmpty) return _emptyMessage('Aucun technicien actif');
          return Column(
            children: top3.map((tech) => _buildTechItem(tech)).toList(),
          );
        },
        loading: _linearLoading,
        error: (e, s) => _inlineError(e),
      ),
    );
  }

  void _openTechnician(TechnicianDetailedStats tech) {
    context.pushNamed(
      'technician-dashboard',
      pathParameters: {'techId': tech.id},
    );
  }

  Widget _buildTechItem(TechnicianDetailedStats tech) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openTechnician(tech),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space16,
            vertical: AppTheme.space12,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.accent.withValues(alpha: 0.1),
                child: Text(
                  tech.prenom.isNotEmpty ? tech.prenom[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accent,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tech.nomComplet,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${tech.sitesDistincts} sites · ${tech.totalHeures.toStringAsFixed(1)}h',
                      style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                    ),
                  ],
                ),
              ),
              Text(
                '${tech.totalInterventions} CRI',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: AppTheme.space4),
              Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textTertiary, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────
  // Vue Sites
  // ──────────────────────────────────────────────────

  Widget _buildSitesView(StatsQuery query, bool isGlobal) {
    final siteStatsAsync = ref.watch(siteStatsProvider(query));

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
        _buildTopSitesChart(query),
        const SizedBox(height: AppTheme.space16),
        if (isGlobal) ...[
          _buildRequestTypesPie(query),
          const SizedBox(height: AppTheme.space16),
        ],
        siteStatsAsync.when(
          data: (sites) {
            if (sites.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(AppTheme.space24),
                child: Center(
                  child: Text('Aucune donnée de site sur cette période',
                      style: TextStyle(color: AppTheme.textTertiary)),
                ),
              );
            }
            return Column(
              children: sites.map((site) => _buildSiteCard(site)).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.space24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, s) => Text('Erreur: $e'),
        ),
      ],
    );
  }

  Widget _buildSiteCard(SiteStats site) {
    final clickable = ref.watch(dashboardIsGlobalProvider);
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          onTap: clickable ? () => _openSite(site) : null,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.space8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Icon(Icons.business_rounded,
                          color: AppTheme.primaryContent, size: 20),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            site.siteNom,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                            ),
                          ),
                          if (site.clientNom != null)
                            Text(
                              '${site.clientNom}${site.ville != null ? ' · ${site.ville}' : ''}',
                              style: TextStyle(
                                  color: AppTheme.textTertiary, fontSize: 13),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space12, vertical: AppTheme.space4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Text(
                        '${site.totalInterventions} CRI',
                        style: TextStyle(
                          color: AppTheme.primaryContent,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space12),
                Divider(height: 1, color: AppTheme.border.withValues(alpha: 0.3)),
                const SizedBox(height: AppTheme.space12),
                // Métriques
                Wrap(
                  spacing: AppTheme.space16,
                  runSpacing: AppTheme.space8,
                  children: [
                    _buildMetric('Récurrence', '${site.tauxRecurrence.toStringAsFixed(0)}%',
                        site.tauxRecurrence > 20 ? AppTheme.error : AppTheme.textSecondary),
                    _buildMetric('Durée moy.', site.dureeMoyenneFormatee, AppTheme.textSecondary),
                    _buildMetric('Techniciens', '${site.techniciensDistincts}', AppTheme.textSecondary),
                    _buildMetric('Services', '${site.totalServices}', AppTheme.textSecondary),
                    _buildMetric('Projets', '${site.totalProjets}', AppTheme.textSecondary),
                  ],
                ),
                // Top catégorie
                if (site.topCategorie != null) ...[
                  const SizedBox(height: AppTheme.space8),
                  Row(
                    children: [
                      Icon(Icons.trending_up_rounded,
                          size: 14, color: AppTheme.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        'Top demande : ${site.topCategorie} (${site.topCategorieCount}x)',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textTertiary,
                            fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ],
                // Dernière intervention
                if (site.derniereIntervention != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 14, color: AppTheme.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        'Dernière : ${DateFormat('dd/MM/yyyy').format(site.derniereIntervention!)}',
                        style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────
  // Vue Techniciens (équipe uniquement)
  // ──────────────────────────────────────────────────

  Widget _buildTechniciansView(StatsQuery query) {
    final techStatsAsync = ref.watch(technicianStatsProvider(query));

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
        _buildTechSiteHeatmap(query),
        const SizedBox(height: AppTheme.space16),
        techStatsAsync.when(
          data: (techs) {
            if (techs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(AppTheme.space24),
                child: Center(
                  child: Text('Aucun technicien actif sur cette période',
                      style: TextStyle(color: AppTheme.textTertiary)),
                ),
              );
            }
            return Column(
              children: techs.map((tech) => _buildTechCard(tech)).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.space24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, s) => Text('Erreur: $e'),
        ),
      ],
    );
  }

  Widget _buildTechCard(TechnicianDetailedStats tech) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          onTap: () => _openTechnician(tech),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                      child: Text(
                        tech.prenom.isNotEmpty
                            ? tech.prenom[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: AppTheme.primaryContent,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tech.nomComplet,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            '${tech.sitesDistincts} sites · ${tech.clientsDistincts} clients',
                            style: TextStyle(
                                color: AppTheme.textTertiary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${tech.totalInterventions} CRI',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '${tech.totalHeures.toStringAsFixed(1)}h',
                          style: TextStyle(
                              color: AppTheme.textTertiary, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space12),
                Divider(height: 1, color: AppTheme.border.withValues(alpha: 0.3)),
                const SizedBox(height: AppTheme.space12),
                // Métriques
                Wrap(
                  spacing: AppTheme.space16,
                  runSpacing: AppTheme.space8,
                  children: [
                    _buildMetric('Durée moy.', tech.dureeMoyenneFormatee, AppTheme.textSecondary),
                    _buildMetric('Services', '${tech.totalServices}', AppTheme.textSecondary),
                    _buildMetric('Projets', '${tech.totalProjets}', AppTheme.textSecondary),
                  ],
                ),
                // Top sites
                if (tech.topSites != null && tech.topSites!.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.space8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.place_rounded,
                          size: 14, color: AppTheme.textTertiary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Sites : ${tech.topSites!.take(3).join(', ')}',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textTertiary,
                              fontStyle: FontStyle.italic),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppTheme.textTertiary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _ViewModeSelector extends StatelessWidget {
  final DashboardViewMode currentMode;
  final bool showTechnicians;
  final Function(DashboardViewMode) onModeChanged;

  const _ViewModeSelector({
    required this.currentMode,
    required this.showTechnicians,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _buildItem('Général', DashboardViewMode.general),
          _buildItem('Sites', DashboardViewMode.parSite),
          if (showTechnicians)
            _buildItem('Techniciens', DashboardViewMode.parTechnicien),
        ],
      ),
    );
  }

  Widget _buildItem(String label, DashboardViewMode mode) {
    // Onglet « Techniciens » mémorisé puis masqué : on retombe sur « Général ».
    final effective = !showTechnicians && currentMode == DashboardViewMode.parTechnicien
        ? DashboardViewMode.general
        : currentMode;
    final isSelected = effective == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => onModeChanged(mode),
        child: AnimatedContainer(
          duration: AppTheme.animFast,
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryContent.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
