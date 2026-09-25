import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/features/dashboard/models/stats_query.dart';
import 'package:novadis_cri/features/dashboard/providers/dashboard_providers.dart';
import 'package:novadis_cri/features/dashboard/widgets/dashboard_cards.dart';
import 'package:novadis_cri/features/dashboard/widgets/intervention_list_item.dart';
import 'package:novadis_cri/models/dashboard_alerts.dart';
import 'package:novadis_cri/models/recent_intervention.dart';

/// Bandeau « À traiter » en tête de la vue Général : sites à forte récurrence,
/// services non résolus depuis longtemps, escalades. Chaque ligne se déplie et
/// chaque élément ouvre le site ou le CRI.
class DashboardAlertsBanner extends ConsumerWidget {
  final StatsQuery query;
  final bool isGlobal;

  const DashboardAlertsBanner({super.key, required this.query, required this.isGlobal});

  static const staleDayChoices = [7, 14, 30];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(dashboardAlertsProvider(query)).when(
          data: (alerts) => alerts.isEmpty
              ? _NoAlert(staleDays: alerts.joursSansResolution)
              : _AlertsCard(alerts: alerts, isGlobal: isGlobal),
          // Pas de squelette : le bandeau ne doit pas faire sauter la page.
          loading: () => const SizedBox.shrink(),
          error: (e, _) => DashboardCard(
            child: DashboardErrorView(
              error: e,
              onRetry: () => ref.invalidate(dashboardAlertsProvider(query)),
            ),
          ),
        );
  }
}

class _NoAlert extends StatelessWidget {
  final int staleDays;
  const _NoAlert({required this.staleDays});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space12,
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppTheme.success, size: 20),
          const SizedBox(width: AppTheme.space8),
          Expanded(
            child: Text(
              'Rien à signaler : pas de site à forte récurrence, pas de service '
              'non résolu depuis plus de $staleDays jours, pas d\'escalade.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertsCard extends ConsumerWidget {
  final DashboardAlerts alerts;
  final bool isGlobal;

  const _AlertsCard({required this.alerts, required this.isGlobal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threshold = alerts.seuilRecurrence.toStringAsFixed(0);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.5)),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space16,
              AppTheme.space12,
              AppTheme.space8,
              AppTheme.space4,
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 20),
                const SizedBox(width: AppTheme.space8),
                Expanded(
                  child: Text(
                    'À traiter',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                // Menu plutôt qu'un DropdownButton dense : celui-ci tronquait « 14 j ».
                PopupMenuButton<int>(
                  tooltip: 'Ancienneté des services non résolus',
                  initialValue: alerts.joursSansResolution,
                  onSelected: (days) =>
                      ref.read(alertStaleDaysProvider.notifier).state = days,
                  itemBuilder: (context) => {
                    ...DashboardAlertsBanner.staleDayChoices,
                    alerts.joursSansResolution,
                  }
                      .map((d) => PopupMenuItem(value: d, child: Text('$d jours')))
                      .toList(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space8,
                      vertical: AppTheme.space4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Non résolus depuis ${alerts.joursSansResolution} j',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        Icon(Icons.arrow_drop_down, size: 18, color: AppTheme.textSecondary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (alerts.sitesRecurrence.isNotEmpty)
            _AlertSection(
              icon: Icons.replay_rounded,
              color: AppTheme.error,
              title: '${alerts.sitesRecurrence.length} site${_s(alerts.sitesRecurrence.length)} '
                  'avec plus de $threshold % de retours',
              children: alerts.sitesRecurrence
                  .map((site) => ListTile(
                        dense: true,
                        title: Text(site.siteNom),
                        subtitle: site.clientNom == null ? null : Text(site.clientNom!),
                        trailing: Text(
                          '${site.tauxRecurrence.toStringAsFixed(0)} % '
                          '(${site.totalRecurrenceRequise}/${site.totalInterventions})',
                          style: const TextStyle(
                            color: AppTheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        // Page site : périmètre équipe uniquement.
                        onTap: isGlobal
                            ? () => context.pushNamed(
                                  'site-dashboard',
                                  pathParameters: {'siteId': site.siteNom},
                                )
                            : null,
                      ))
                  .toList(),
            ),
          if (alerts.criNonResolusTotal > 0)
            _AlertSection(
              icon: Icons.pending_actions_rounded,
              color: AppTheme.warning,
              title: '${alerts.criNonResolusTotal} service${_s(alerts.criNonResolusTotal)} '
                  'non résolu${_s(alerts.criNonResolusTotal)} depuis plus de '
                  '${alerts.joursSansResolution} jours',
              children: _interventions(context, alerts.criNonResolus, alerts.criNonResolusTotal),
            ),
          if (alerts.escaladesTotal > 0)
            _AlertSection(
              icon: Icons.trending_up_rounded,
              color: AppTheme.error,
              title: '${alerts.escaladesTotal} escalade${_s(alerts.escaladesTotal)} niveau 2 '
                  'sur la période',
              children: _interventions(context, alerts.escalades, alerts.escaladesTotal),
            ),
          const SizedBox(height: AppTheme.space4),
        ],
      ),
    );
  }

  static String _s(int n) => n > 1 ? 's' : '';

  List<Widget> _interventions(
    BuildContext context,
    List<RecentIntervention> items,
    int total,
  ) {
    return [
      ...items.map((item) => MobileInterventionListItem(
            type: '${item.typeLabel} · ${item.siteNom ?? item.clientNom}',
            client: isGlobal ? item.technicienNom : item.category,
            date: item.interventionDate,
            status: item.statusLabel,
            onTap: () => context.pushNamed(
              'cri-view',
              pathParameters: {'id': item.id},
              queryParameters: {'type': item.source},
            ),
          )),
      if (total > items.length)
        Padding(
          padding: const EdgeInsets.all(AppTheme.space12),
          child: Text(
            '… et ${total - items.length} autre${_s(total - items.length)}',
            style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
          ),
        ),
    ];
  }
}

class _AlertSection extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final List<Widget> children;

  const _AlertSection({
    required this.icon,
    required this.color,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      // Pas de traits au-dessus / au-dessous de la tuile dépliée.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(icon, color: color, size: 20),
        title: Text(
          title,
          style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
        ),
        childrenPadding: const EdgeInsets.only(bottom: AppTheme.space8),
        children: children,
      ),
    );
  }
}
