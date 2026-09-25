import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:novadis_cri/models/user_role.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/core/theme/theme_provider.dart';
import 'package:novadis_cri/core/utils/duration_format.dart';
import 'package:novadis_cri/core/widgets/content_container.dart';
import 'package:novadis_cri/features/dashboard/models/dashboard_models.dart';
import 'package:novadis_cri/features/dashboard/models/stats_query.dart';
import 'package:novadis_cri/features/dashboard/providers/dashboard_providers.dart';
import 'package:novadis_cri/features/dashboard/views/general_view.dart';
import 'package:novadis_cri/features/dashboard/widgets/dashboard_cards.dart';
import 'package:novadis_cri/features/dashboard/widgets/dashboard_common_widgets.dart';
import 'package:novadis_cri/features/dashboard/widgets/intervention_list_item.dart';

/// Dashboard d'un technicien (périmètre équipe) : identifié par son ID utilisateur.
class TechnicianDashboardPage extends ConsumerWidget {
  final String technicianId;

  const TechnicianDashboardPage({super.key, required this.technicianId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeAnimationProvider);
    final query = ref.watch(dashboardQueryProvider).copyWith(
          technicianId: technicianId,
        );
    final technician = ref
        .watch(techniciansProvider)
        .valueOrNull
        ?.where((t) => t.id == technicianId)
        .firstOrNull;

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
      body: ContentContainer(
        maxWidth: 1000,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.space16),
          children: [
            _TechnicianHeader(technician: technician),
            const SizedBox(height: AppTheme.space16),
            const Align(
              alignment: Alignment.centerLeft,
              child: DashboardPeriodFilter(),
            ),
            const SizedBox(height: AppTheme.space24),
            DashboardKpis(query: query),
            const SizedBox(height: AppTheme.space24),
            EvolutionCard(query: query),
            const SizedBox(height: AppTheme.space24),
            _FrequentSites(query: query),
            const SizedBox(height: AppTheme.space24),
            _RecentInterventions(query: query),
          ],
        ),
      ),
    );
  }
}

class _FrequentSites extends ConsumerWidget {
  final StatsQuery query;
  const _FrequentSites({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sites = ref.watch(siteStatsProvider(query)).valueOrNull ?? const [];
    if (sites.isEmpty) return const SizedBox.shrink();

    return _Card(
      title: 'Sites fréquents',
      child: Column(
        children: sites.take(5).map((site) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.business, color: AppTheme.primaryContent),
            title: Text(
              site.siteNom,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            subtitle: Text(
              '${site.totalInterventions} interventions',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            trailing: Icon(Icons.chevron_right, color: AppTheme.textTertiary),
            onTap: () => context.pushNamed(
              'site-dashboard',
              pathParameters: {'siteId': site.siteNom},
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RecentInterventions extends ConsumerWidget {
  final StatsQuery query;
  const _RecentInterventions({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Card(
      title: 'Dernières interventions',
      child: ref.watch(recentInterventionsProvider((query: query, limit: 10))).when(
            data: (items) => items.isEmpty
                ? Text(
                    'Aucune intervention sur la période',
                    style: TextStyle(color: AppTheme.textTertiary),
                  )
                : Column(
                    children: items
                        .map(
                          (item) => MobileInterventionListItem(
                            type: item.typeLabel,
                            client:
                                '${item.siteNom ?? item.clientNom} - ${formatDurationMinutes(item.dureeMinutes ?? 0)}',
                            date: item.interventionDate,
                            status: item.statusLabel,
                            onTap: () => context.pushNamed(
                              'cri-view',
                              pathParameters: {'id': item.id},
                              queryParameters: {'type': item.source},
                            ),
                          ),
                        )
                        .toList(),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => DashboardErrorView(
              error: e,
              onRetry: () => ref.invalidate(
                recentInterventionsProvider((query: query, limit: 10)),
              ),
            ),
          ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

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
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          child,
        ],
      ),
    );
  }
}

class _TechnicianHeader extends StatelessWidget {
  /// `null` pendant le chargement (ou technicien désactivé depuis).
  final TechnicianModel? technician;
  const _TechnicianHeader({required this.technician});

  @override
  Widget build(BuildContext context) {
    final name = technician?.name ?? '…';
    final initials = name.trim().isEmpty || name == '…'
        ? '?'
        : name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join();

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
              initials,
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
                  name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (technician?.role != null)
                  Text(
                    UserRole.fromString(technician!.role)?.label ??
                        technician!.role!,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.primaryContent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (technician?.email != null) ...[
                  const SizedBox(height: AppTheme.space4),
                  Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: AppTheme.space8),
                      Flexible(
                        child: Text(
                          technician!.email!,
                          style: TextStyle(color: AppTheme.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
