import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/features/dashboard/widgets/dashboard_cards.dart';
import 'package:novadis_cri/models/site_stats.dart';

/// Seuil au-delà duquel le taux de récurrence d'un site est signalé.
const double kRecurrenceAlertThreshold = 20;

/// Ouvre la page d'un site (route réservée au périmètre équipe).
void openSiteDashboard(BuildContext context, SiteStats site) {
  context.pushNamed('site-dashboard', pathParameters: {'siteId': site.siteNom});
}

/// Ligne compacte d'un site (blocs de synthèse).
class SiteListTile extends StatelessWidget {
  final SiteStats site;
  final VoidCallback? onTap;

  const SiteListTile({super.key, required this.site, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
                  _CriBadge(count: site.totalInterventions),
                  if (site.topCategorie != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      site.topCategorie!,
                      style: TextStyle(fontSize: 11, color: AppTheme.textTertiary),
                    ),
                  ],
                ],
              ),
              if (onTap != null) ...[
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
}

/// Carte détaillée d'un site (onglet Sites).
class SiteStatsCard extends StatelessWidget {
  final SiteStats site;
  final VoidCallback? onTap;

  const SiteStatsCard({super.key, required this.site, this.onTap});

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(fontSize: 12, color: AppTheme.textTertiary);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space8),
      child: DashboardCard(
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      _CriBadge(count: site.totalInterventions, large: true),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space12),
                  Divider(height: 1, color: AppTheme.border.withValues(alpha: 0.3)),
                  const SizedBox(height: AppTheme.space12),
                  Wrap(
                    spacing: AppTheme.space16,
                    runSpacing: AppTheme.space8,
                    children: [
                      DashboardMetric(
                        'Récurrence',
                        '${site.tauxRecurrence.toStringAsFixed(0)}%',
                        valueColor: site.tauxRecurrence > kRecurrenceAlertThreshold
                            ? AppTheme.error
                            : null,
                      ),
                      DashboardMetric('Durée moy.', site.dureeMoyenneFormatee),
                      DashboardMetric('Techniciens', '${site.techniciensDistincts}'),
                      DashboardMetric('Services', '${site.totalServices}'),
                      DashboardMetric('Projets', '${site.totalProjets}'),
                    ],
                  ),
                  if (site.topCategorie != null) ...[
                    const SizedBox(height: AppTheme.space8),
                    Row(
                      children: [
                        Icon(Icons.trending_up_rounded,
                            size: 14, color: AppTheme.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          'Top demande : ${site.topCategorie} (${site.topCategorieCount}x)',
                          style: muted.copyWith(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ],
                  if (site.derniereIntervention != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 14, color: AppTheme.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          'Dernière : ${DateFormat('dd/MM/yyyy').format(site.derniereIntervention!)}',
                          style: muted,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CriBadge extends StatelessWidget {
  final int count;
  final bool large;
  const _CriBadge({required this.count, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? AppTheme.space12 : AppTheme.space8,
        vertical: AppTheme.space4,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryContent.withValues(alpha: large ? 0.1 : 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(
        '$count CRI',
        style: TextStyle(
          color: AppTheme.primaryContent,
          fontWeight: large ? FontWeight.w700 : FontWeight.w600,
          fontSize: large ? 14 : 12,
        ),
      ),
    );
  }
}
