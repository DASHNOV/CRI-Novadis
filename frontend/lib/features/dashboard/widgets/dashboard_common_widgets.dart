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
