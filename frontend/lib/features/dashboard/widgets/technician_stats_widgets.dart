import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/features/dashboard/widgets/dashboard_cards.dart';
import 'package:novadis_cri/models/technician_detailed_stats.dart';

/// Ouvre la page d'un technicien (identifié par son ID utilisateur).
void openTechnicianDashboard(BuildContext context, TechnicianDetailedStats tech) {
  context.pushNamed('technician-dashboard', pathParameters: {'techId': tech.id});
}

String _initial(TechnicianDetailedStats tech) =>
    tech.prenom.isNotEmpty ? tech.prenom[0].toUpperCase() : '?';

/// Ligne compacte d'un technicien (blocs de synthèse).
class TechnicianListTile extends StatelessWidget {
  final TechnicianDetailedStats tech;
  final VoidCallback? onTap;

  const TechnicianListTile({super.key, required this.tech, this.onTap});

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
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.accent.withValues(alpha: 0.1),
                child: Text(
                  _initial(tech),
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

/// Carte détaillée d'un technicien (onglet Techniciens).
class TechnicianStatsCard extends StatelessWidget {
  final TechnicianDetailedStats tech;
  final VoidCallback? onTap;

  const TechnicianStatsCard({super.key, required this.tech, this.onTap});

  @override
  Widget build(BuildContext context) {
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
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                        child: Text(
                          _initial(tech),
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
                  Wrap(
                    spacing: AppTheme.space16,
                    runSpacing: AppTheme.space8,
                    children: [
                      DashboardMetric('Durée moy.', tech.dureeMoyenneFormatee),
                      DashboardMetric('Services', '${tech.totalServices}'),
                      DashboardMetric('Projets', '${tech.totalProjets}'),
                      DashboardMetric('Résolues', '${tech.totalResolu}'),
                      DashboardMetric('Récurrences', '${tech.totalRecurrenceRequise}'),
                    ],
                  ),
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
      ),
    );
  }
}
