import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:novadis_cri/models/user_role.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/features/dashboard/models/dashboard_models.dart';
import 'package:novadis_cri/features/dashboard/providers/dashboard_providers.dart';
import 'package:novadis_cri/features/dashboard/widgets/dashboard_common_widgets.dart';

import 'package:novadis_cri/features/dashboard/widgets/intervention_trend_chart_widget.dart';
import 'package:novadis_cri/features/dashboard/config/chart_config.dart';
import 'package:novadis_cri/core/theme/theme_provider.dart';

/// Dashboard spécifique à un Technicien
class TechnicianDashboardPage extends ConsumerStatefulWidget {
  final String technicianId; // Using name as ID for now based on previous code

  const TechnicianDashboardPage({super.key, required this.technicianId});

  @override
  ConsumerState<TechnicianDashboardPage> createState() =>
      _TechnicianDashboardPageState();
}

class _TechnicianDashboardPageState
    extends ConsumerState<TechnicianDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTechnician();
    });
  }

  Future<void> _loadTechnician() async {
    final technicians = await ref.read(techniciansListProvider.future);
    try {
      final tech = technicians.firstWhere(
        (t) => t.id == widget.technicianId,
        orElse: () => technicians.first,
      );
      ref.read(selectedTechnicianProvider.notifier).state = tech;
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeAnimationProvider);
    final techStatsAsync = ref.watch(technicianStatsProvider);
    final selectedTech = ref.watch(selectedTechnicianProvider);
    final selectedPeriod = ref.watch(selectedPeriodProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Dashboard Technicien'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: selectedTech == null
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(AppTheme.space16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _TechnicianHeader(technician: selectedTech),
                      const SizedBox(height: AppTheme.space16),

                      // Filtre de période
                      PeriodFilterWidget(
                        selectedPeriod: selectedPeriod,
                        onPeriodChanged: (period) {
                          ref
                              .read(selectedPeriodProvider.notifier)
                              .setPeriod(period);
                        },
                      ),
                      const SizedBox(height: AppTheme.space24),

                      techStatsAsync.when(
                        data: (stats) {
                          if (stats == null) {
                            return const Center(child: Text("Pas de données"));
                          }
                          return Column(
                            children: [
                              // 1. Informations sur les sites affectés & Interventions réalisées
                              Row(
                                children: [
                                  Expanded(
                                    child: _SimpleKpiCard(
                                      title: 'Affectées',
                                      value:
                                          '${stats.kpis.assignedInterventions}',
                                      icon: Icons.assignment,
                                      color: ChartConfig
                                          .kpiColors['interventions']!,
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.space16),
                                  Expanded(
                                    child: _SimpleKpiCard(
                                      title: 'Réalisées',
                                      value:
                                          '${stats.kpis.completedInterventions}',
                                      icon: Icons.check_circle_outline,
                                      color: ChartConfig.kpiColors['sites']!,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.space24),

                              // 2. Graphique avec le nombre d'intervention en fonction temps
                              InterventionTrendChartWidget(
                                data: stats.workloadCurve,
                                title: 'Interventions',
                                subtitle: 'Nombre d\'interventions par semaine',
                              ),
                              const SizedBox(height: AppTheme.space24),

                              const SizedBox(height: AppTheme.space24),

                              // 3. (Deleted)

                              // 4. Site fréquenté
                              const SizedBox(height: AppTheme.space24),

                              // 4. Site fréquenté
                              if (stats.topSites.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.all(AppTheme.space16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface,
                                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                                    border: Border.all(color: AppTheme.border),
                                    boxShadow: AppTheme.shadowSm,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sites Fréquents',
                                        style: AppTheme
                                            .lightTheme
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: AppTheme.textPrimary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: AppTheme.space12),
                                      Column(
                                        children: stats.topSites
                                            .map(
                                              (site) => InkWell(
                                                onTap: () => context.pushNamed(
                                                  'site-dashboard',
                                                  pathParameters: {
                                                    'siteId': site.siteId,
                                                  },
                                                ),
                                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 8.0,
                                                      ),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              AppTheme.space8,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: AppTheme
                                                              .surfaceVariant,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                AppTheme.radiusMd,
                                                              ),
                                                        ),
                                                        child: const Icon(
                                                          Icons.business,
                                                          size: 20,
                                                          color: AppTheme
                                                              .primary,
                                                        ),
                                                      ),
                                                      const SizedBox(width: AppTheme.space12),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              site.siteName,
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: AppTheme.textPrimary,
                                                              ),
                                                            ),
                                                            Text(
                                                              '${site.visitCount} visites',
                                                              style: TextStyle(
                                                                color: AppTheme.textSecondary,
                                                                fontSize: 13,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Icon(
                                                        Icons.chevron_right,
                                                        color: AppTheme.textTertiary,
                                                        size: 20,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppTheme.space24),
                              ],
                            ],
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, s) => Text('Erreur: $e'),
                      ),
                    ]),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: AppTheme.space24)),
              ],
            ),
    );
  }
}

class _SimpleKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SimpleKpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: AppTheme.space12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TechnicianHeader extends StatelessWidget {
  final TechnicianModel technician;
  const _TechnicianHeader({required this.technician});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      padding: const EdgeInsets.all(AppTheme.space20),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              technician.name.isNotEmpty
                  ? technician.name.substring(0, 2).toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  technician.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  UserRole.fromString(technician.role)?.label ??
                      technician.role ??
                      'Technicien',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.primaryContent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppTheme.space4),
                Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: AppTheme.space8),
                    Text(
                      technician.email,
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
