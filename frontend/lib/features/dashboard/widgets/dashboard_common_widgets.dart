import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/features/dashboard/models/dashboard_models.dart';
import 'package:novadis_cri/features/dashboard/providers/dashboard_providers.dart';

/// Filtre de période (pilules), branché sur [selectedPeriodProvider] et
/// [customRangeProvider] : « Personnalisée » ouvre un sélecteur de dates.
class DashboardPeriodFilter extends ConsumerWidget {
  const DashboardPeriodFilter({super.key});

  static final _dayFormat = DateFormat('dd/MM/yy');

  Future<void> _pickRange(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = ref.read(customRangeProvider);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: today,
      initialDateRange: current ??
          DateTimeRange(start: today.subtract(const Duration(days: 29)), end: today),
      helpText: 'Période du dashboard',
      saveText: 'Appliquer',
    );
    if (picked == null) return;
    await ref.read(customRangeProvider.notifier).setRange(picked);
    await ref.read(selectedPeriodProvider.notifier).setPeriod(DashboardPeriod.custom);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final range = ref.watch(customRangeProvider);

    String labelOf(DashboardPeriod period) {
      if (period == DashboardPeriod.custom &&
          selectedPeriod == DashboardPeriod.custom &&
          range != null) {
        return '${_dayFormat.format(range.start)} → ${_dayFormat.format(range.end)}';
      }
      return period.label;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: AppTheme.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: DashboardPeriod.values.map((period) {
            final isSelected = period == selectedPeriod;
            return GestureDetector(
              onTap: () => period == DashboardPeriod.custom
                  ? _pickRange(context, ref)
                  : ref.read(selectedPeriodProvider.notifier).setPeriod(period),
              child: AnimatedContainer(
                duration: AppTheme.animFast,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (period == DashboardPeriod.custom) ...[
                      Icon(
                        Icons.date_range_rounded,
                        size: 14,
                        color: isSelected
                            ? AppTheme.textOnPrimary
                            : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      labelOf(period),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected
                            ? AppTheme.textOnPrimary
                            : AppTheme.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Widget de sélection de technicien
class TechnicianSelectorWidget extends StatelessWidget {
  final List<TechnicianModel> technicians;
  final TechnicianModel? selectedTechnician;
  final Function(TechnicianModel?)? onTechnicianChanged;
  final bool isLoading;

  const TechnicianSelectorWidget({
    super.key,
    required this.technicians,
    this.selectedTechnician,
    this.onTechnicianChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
      ),
      child: isLoading
          ? _buildLoadingState()
          : DropdownButtonHideUnderline(
              child: DropdownButton<TechnicianModel?>(
                value: selectedTechnician,
                hint: Row(
                  children: [
                    Icon(Icons.person_search, size: 20, color: AppTheme.textTertiary),
                    const SizedBox(width: 8),
                    Text(
                      'Sélectionner un technicien',
                      style: TextStyle(color: AppTheme.textTertiary),
                    ),
                  ],
                ),
                icon: Icon(Icons.keyboard_arrow_down, color: AppTheme.textTertiary),
                isExpanded: true,
                items: [
                  DropdownMenuItem<TechnicianModel?>(
                    value: null,
                    child: Text(
                      'Sélectionner un technicien',
                      style: TextStyle(color: AppTheme.textTertiary),
                    ),
                  ),
                  ...technicians.map((tech) {
                    return DropdownMenuItem<TechnicianModel>(
                      value: tech,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                            child: Text(
                              tech.name.isNotEmpty
                                  ? tech.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: AppTheme.primaryContent,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  tech.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                if (tech.email != null)
                                  Text(
                                    tech.email!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textTertiary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                onChanged: onTechnicianChanged,
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primaryContent,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Chargement des techniciens...',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Widget d'en-tête du dashboard
class DashboardHeaderWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final DateTime? lastUpdated;
  final VoidCallback? onRefresh;

  const DashboardHeaderWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.lastUpdated,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
              if (lastUpdated != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.update, size: 14, color: AppTheme.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      'Mis à jour: ${_formatDateTime(lastUpdated!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (onRefresh != null)
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
            style: IconButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
            ),
          ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'à l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'il y a ${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return 'il y a ${difference.inHours}h';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

/// Badge de statut (online/offline)
class ConnectionStatusBadge extends StatelessWidget {
  final bool isOnline;

  const ConnectionStatusBadge({super.key, this.isOnline = true});

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? AppTheme.success : AppTheme.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOnline ? 'En ligne' : 'Hors ligne',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
