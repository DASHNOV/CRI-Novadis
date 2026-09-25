import 'package:flutter/material.dart';
import 'package:novadis_cri/features/dashboard/config/chart_config.dart';
import 'package:novadis_cri/features/dashboard/models/dashboard_models.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/core/utils/duration_format.dart';

/// Widget pour afficher les KPIs du technicien
class TechnicianKpiCardsWidget extends StatelessWidget {
  final TechnicianKpis kpis;
  final bool isLoading;

  const TechnicianKpiCardsWidget({
    super.key,
    required this.kpis,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('📊 Volume d\'intervention'),
        const SizedBox(height: 12),
        _buildVolumeKpis(),

        const SizedBox(height: 24),
        _buildSectionTitle('⏱️ Performance Temporelle'),
        const SizedBox(height: 12),
        _buildTimeKpis(),

        const SizedBox(height: 24),
        _buildSectionTitle('⭐ Performance Qualité'),
        const SizedBox(height: 12),
        _buildQualityKpis(),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildVolumeKpis() {
    return Row(
      children: [
        Expanded(
          child: _TechnicianKpiCard(
            title: 'Affectées',
            value: '${kpis.assignedInterventions}',
            icon: Icons.assignment,
            color: ChartConfig.kpiColors['interventions']!,
            isLoading: isLoading,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TechnicianKpiCard(
            title: 'Réalisées',
            value: '${kpis.completedInterventions}',
            icon: Icons.check_circle_outline,
            color: ChartConfig.kpiColors['sites']!,
            isLoading: isLoading,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TechnicianKpiCard(
            title: 'vs Équipe',
            value: '${kpis.teamComparison.toStringAsFixed(0)}%',
            icon: Icons.people,
            color: AppTheme.accent,
            trend: kpis.teamComparison > 100
                ? 'up'
                : (kpis.teamComparison < 100 ? 'down' : null),
            isLoading: isLoading,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeKpis() {
    final deviation = kpis.standardDeviation;
    final standardDevSign = (deviation ?? 0) >= 0 ? '+' : '';
    final standardDevColor = deviation == null || deviation == 0
        ? AppTheme.textTertiary
        : (deviation < 0
              ? ChartConfig.trendUpColor
              : ChartConfig.trendDownColor);

    return Row(
      children: [
        Expanded(
          child: _TechnicianKpiCard(
            title: 'Durée Moy.',
            value: kpis.formattedAverageDuration,
            icon: Icons.timer,
            color: ChartConfig.kpiColors['duration']!,
            isLoading: isLoading,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TechnicianKpiCard(
            title: 'Écart Std',
            value: deviation == null
                ? '—'
                : '$standardDevSign${formatDurationMinutes(deviation.abs())}',
            icon: Icons.trending_flat,
            color: standardDevColor,
            subtitle: deviation == null
                ? 'Non mesuré'
                : (deviation < 0 ? 'Plus rapide' : 'Plus lent'),
            isLoading: isLoading,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TechnicianKpiCard(
            title: 'Ponctualité',
            value: kpis.punctualityRate == null
                ? '—'
                : '${kpis.punctualityRate!.toStringAsFixed(0)}%',
            icon: Icons.access_time_filled,
            color: ChartConfig.kpiColors['punctuality']!,
            subtitle: kpis.punctualityRate == null ? 'Non mesurée' : '±15min',
            isLoading: isLoading,
          ),
        ),
      ],
    );
  }

  Widget _buildQualityKpis() {
    return Row(
      children: [
        Expanded(
          child: _TechnicianKpiCard(
            title: 'Interventions',
            value: '${kpis.assignedInterventions}',
            icon: Icons.analytics_outlined,
            color: AppTheme.accent,
            isLoading: isLoading,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TechnicianKpiCard(
            title: '1er Passage',
            value: '${kpis.firstTimeFixRate.toStringAsFixed(0)}%',
            icon: Icons.done_all,
            color: ChartConfig.kpiColors['firstFix']!,
            subtitle: 'Sans retour',
            isLoading: isLoading,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TechnicianKpiCard(
            title: 'Escalades',
            value: '${kpis.escalationRate.toStringAsFixed(0)}%',
            icon: Icons.arrow_upward,
            color: ChartConfig.kpiColors['escalation']!,
            subtitle: 'Niveau 2',
            isLoading: isLoading,
          ),
        ),
      ],
    );
  }
}

/// Carte KPI individuelle pour technicien
class _TechnicianKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final String? trend;
  final bool isLoading;

  const _TechnicianKpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.trend,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      child: isLoading ? _buildSkeleton() : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            if (trend != null) ...[
              const Spacer(),
              Icon(
                trend == 'up' ? Icons.arrow_upward : Icons.arrow_downward,
                color: trend == 'up'
                    ? ChartConfig.trendUpColor
                    : ChartConfig.trendDownColor,
                size: 12,
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 2),
        Flexible(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 1),
          Flexible(
            child: Text(
              subtitle!,
              style: TextStyle(fontSize: 9, color: AppTheme.textTertiary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 50,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 60,
          height: 12,
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

