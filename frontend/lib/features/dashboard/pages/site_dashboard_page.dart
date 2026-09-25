import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/core/theme/theme_provider.dart';
import 'package:novadis_cri/core/widgets/content_container.dart';
import 'package:novadis_cri/features/dashboard/models/stats_query.dart';
import 'package:novadis_cri/features/dashboard/providers/dashboard_providers.dart';
import 'package:novadis_cri/features/dashboard/widgets/time_evolution_chart_widget.dart';
import 'package:novadis_cri/models/recent_intervention.dart';
import 'package:novadis_cri/models/site_stats.dart';
import 'package:novadis_cri/models/technician_detailed_stats.dart';

/// Dashboard d'un site (périmètre équipe), sur tout son historique.
/// [siteId] : nom du site, tel que regroupé par les stats par site.
class SiteDashboardPage extends ConsumerWidget {
  final String siteId;

  const SiteDashboardPage({super.key, required this.siteId});

  /// Nombre d'interventions affichées dans l'historique.
  static const _historyLimit = 100;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeAnimationProvider);
    final query = StatsQuery.allTime(site: siteId);
    final siteAsync = ref.watch(siteStatsProvider(query));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Dashboard Site'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: siteAsync.when(
        data: (sites) => sites.isEmpty
            ? Center(
                child: Text(
                  'Aucune intervention pour ce site',
                  style: TextStyle(color: AppTheme.textTertiary),
                ),
              )
            : ContentContainer(
                maxWidth: 1000,
                child: _buildContent(context, ref, query, sites.first),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur: $error')),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    StatsQuery query,
    SiteStats site,
  ) {
    final history = ref
            .watch(recentInterventionsProvider((query: query, limit: _historyLimit)))
            .valueOrNull ??
        const <RecentIntervention>[];
    final technicians =
        ref.watch(technicianStatsProvider(query)).valueOrNull ?? const [];

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppTheme.space16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _SiteHeaderCard(site: site),
              const SizedBox(height: AppTheme.space16),

              Text(
                'Performance du Site',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: AppTheme.space12),
              _SiteStatsRow(site: site),
              const SizedBox(height: AppTheme.space24),

              ref.watch(evolutionProvider(query)).when(
                    data: (evolution) => TimeEvolutionChartWidget(
                      data: evolution.points,
                      title: 'Interventions',
                      subtitle:
                          'Depuis la première intervention, ${evolution.granularityLabel}',
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Erreur: $e'),
                  ),
              const SizedBox(height: AppTheme.space24),

              _TechniciansList(technicians: technicians),
              const SizedBox(height: AppTheme.space24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Historique Interventions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    site.totalInterventions > history.length
                        ? '${history.length} dernières sur ${site.totalInterventions}'
                        : '${site.totalInterventions} totales',
                    style: TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space12),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final intervention = history[index];
              return _TimelineItem(
                intervention: intervention,
                isLast: index == history.length - 1,
                onTap: () => context.pushNamed(
                  'cri-view',
                  pathParameters: {'id': intervention.id},
                  queryParameters: {'type': intervention.source},
                ),
              );
            }, childCount: history.length),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: AppTheme.space24)),
      ],
    );
  }
}

class _SiteHeaderCard extends StatelessWidget {
  final SiteStats site;

  const _SiteHeaderCard({required this.site});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryContent.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppTheme.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: const Icon(
                  Icons.business,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppTheme.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      site.siteNom,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      site.clientNom ?? '',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (site.ville != null) ...[
            const SizedBox(height: AppTheme.space20),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 18,
                ),
                const SizedBox(width: AppTheme.space8),
                Expanded(
                  child: Text(
                    site.ville!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SiteStatsRow extends StatelessWidget {
  final SiteStats site;

  const _SiteStatsRow({required this.site});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total Interv.',
            value: site.totalInterventions.toString(),
            icon: Icons.assignment,
            color: AppTheme.primaryContent,
          ),
        ),
        const SizedBox(width: AppTheme.space12),
        Expanded(
          child: _StatCard(
            label: 'Durée moy.',
            value: site.dureeMoyenneFormatee,
            icon: Icons.timer,
            color: AppTheme.success,
          ),
        ),
        const SizedBox(width: AppTheme.space12),
        Expanded(
          child: _StatCard(
            label: 'Récurrence',
            value: '${site.tauxRecurrence.toStringAsFixed(0)}%',
            icon: Icons.replay,
            color: site.tauxRecurrence > 20 ? AppTheme.error : AppTheme.warning,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
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
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
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
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: AppTheme.space12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TechniciansList extends StatelessWidget {
  final List<TechnicianDetailedStats> technicians;

  const _TechniciansList({required this.technicians});

  @override
  Widget build(BuildContext context) {
    if (technicians.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Techniciens Intervenants',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.space12),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: technicians.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppTheme.space12),
            itemBuilder: (context, index) {
              final tech = technicians[index];
              final techName = tech.nomComplet.trim();
              return GestureDetector(
                onTap: () => context.pushNamed(
                  'technician-dashboard',
                  pathParameters: {'techId': tech.id},
                ),
                child: Container(
                  width: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: AppTheme.shadowSm,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
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
                          techName.isNotEmpty ? techName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.space8),
                      Text(
                        techName.split(' ').first,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final RecentIntervention intervention;
  final bool isLast;
  final VoidCallback onTap;

  const _TimelineItem({
    required this.intervention,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy', 'fr_FR');
    final realized = intervention.isProject
        ? intervention.projectStatus == 'termine'
        : intervention.resolutionStatus == 'resolu';
    final inProgress = intervention.isProject
        ? intervention.projectStatus == 'enCours'
        : intervention.resolutionStatus == 'partiellementResolu';
    final statusColor = realized
        ? AppTheme.success
        : (inProgress ? AppTheme.primaryLight : AppTheme.error);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne temporelle
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: statusColor, width: 3),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: AppTheme.border),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.space12),
          // Carte
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.space16),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.space12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: AppTheme.shadowSm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateFormat.format(intervention.interventionDate),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textTertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                            ),
                            child: Text(
                              intervention.statusLabel,
                              style: TextStyle(
                                fontSize: 10,
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space8),
                      Text(
                        '${intervention.typeLabel} · ${intervention.category}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space4),
                      Text(
                        'Tech: ${intervention.technicienNom}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
