import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/core/utils/duration_format.dart';
import 'package:novadis_cri/data/models/site_summary_model.dart';

class SiteSummaryCard extends StatelessWidget {
  final SiteSummaryModel summary;
  final VoidCallback onDismiss;
  final VoidCallback onSeeHistory;

  const SiteSummaryCard({
    super.key,
    required this.summary,
    required this.onDismiss,
    required this.onSeeHistory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
        boxShadow: AppTheme.shadowMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusLg),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.analytics_outlined,
                  color: AppTheme.textOnPrimary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'RÉSUMÉ DU SITE : ${summary.siteName.toUpperCase()}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textOnPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onDismiss,
                  color: AppTheme.textOnPrimary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Alert Logic
          if (summary.chronicityAlert)
            Container(
              padding: const EdgeInsets.all(12),
              color: AppTheme.warning.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ALERTE : Problème chronique détecté',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppTheme.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (summary.chronicProblemDescription != null)
                          Text(
                            summary.chronicProblemDescription!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.warning,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Flash Info
                _buildFlashInfo(context),
                const Divider(height: 24),

                // Timeline
                if (summary.timeline.isNotEmpty) ...[
                  _buildSectionTitle(context, 'DERNIERS ÉVÉNEMENTS'),
                  const SizedBox(height: 8),
                  ...summary.timeline.map((e) => _buildTimelineItem(context, e)),
                  const Divider(height: 24),
                ],

                // Technical Heritage
                if (summary.recommendations.isNotEmpty) ...[
                  _buildSectionTitle(context, 'CONSEILS TECHNIQUES'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: summary.recommendations.map((rec) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  rec,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSeeHistory,
                    child: const Text('HISTORIQUE COMPLET'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onDismiss,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('OK, COMPRIS'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashInfo(BuildContext context) {
    final hasTrend = summary.resolutionTrend != 'Inconnu';
    final hasDuration = summary.averageDurationMinutes != null;
    final hasTechnician = summary.mostFrequentTechnician != null &&
        summary.mostFrequentTechnician!.isNotEmpty;
    final showSecondRow = hasTrend || hasDuration || hasTechnician;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildIndicator(
              context,
              'Interventions (6 mois)',
              summary.recurrenceLast6Months.toString(),
              summary.recurrenceLast6Months > 5 ? AppTheme.warning : AppTheme.success,
            ),
          ],
        ),
        if (showSecondRow) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (hasTrend)
                _buildIndicator(
                  context,
                  'Tendance',
                  summary.resolutionTrend,
                  _getTrendColor(summary.resolutionTrend),
                  icon: _getTrendIcon(summary.resolutionTrend),
                ),
              if (hasDuration)
                _buildIndicator(
                  context,
                  'Durée moy.',
                  '~${formatDurationMinutes(summary.averageDurationMinutes!)}',
                  AppTheme.textTertiary,
                  icon: Icons.timer_outlined,
                ),
              if (hasTechnician)
                _buildIndicator(
                  context,
                  'Expert du site',
                  summary.mostFrequentTechnician!.split(' ').first,
                  Theme.of(context).colorScheme.primary,
                  icon: Icons.person_outline,
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildIndicator(
    BuildContext context,
    String label,
    String value,
    Color color, {
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        if (icon != null)
          Icon(icon, color: color, size: 24)
        else
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryContent,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    SiteTimelineEventModel event,
  ) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM');
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Text(
              dateFormat.format(event.date),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 4, right: 8),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getStatusColor(event.status),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.identifiedCause.isNotEmpty 
                      ? event.identifiedCause 
                      : 'Intervention standard',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (event.replacedParts.isNotEmpty && event.replacedParts != '-')
                  Text(
                    'Pièces: ${event.replacedParts}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'résolu':
      case 'resolu':
        return AppTheme.success;
      case 'partiel':
      case 'partiellementresolu':
        return AppTheme.warning;
      case 'non résolu':
      case 'nonresolu':
        return AppTheme.error;
      default:
        return AppTheme.textTertiary;
    }
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'Amélioration':
        return AppTheme.success;
      case 'Dégradation':
        return AppTheme.error;
      case 'Stable':
        return AppTheme.warning;
      default:
        return AppTheme.textTertiary;
    }
  }

  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case 'Amélioration':
        return Icons.trending_up;
      case 'Dégradation':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }
}

