import 'package:flutter/material.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';

/// Message d'erreur d'un bloc du dashboard, avec « Réessayer ».
///
/// [StatsApiService] lève des messages déjà rédigés (`String`) : on les affiche
/// tels quels ; toute autre erreur est affichée sans le préfixe « Exception: ».
class DashboardErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const DashboardErrorView({
    super.key,
    required this.error,
    required this.onRetry,
  });

  static String messageOf(Object error) {
    if (error is String) return error;
    return error.toString().replaceFirst(RegExp(r'^\w*Exception:\s*'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.space16),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
          const SizedBox(width: AppTheme.space8),
          Expanded(
            child: Text(
              messageOf(error),
              style: const TextStyle(color: AppTheme.error, fontSize: 13),
            ),
          ),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

/// Cadre commun des blocs du dashboard.
class DashboardCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const DashboardCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
        boxShadow: AppTheme.shadowSm,
      ),
      child: child,
    );
  }
}

/// Bloc avec titre et action (« Voir tous », « Historique »…).
class DashboardSectionCard extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final Widget child;

  const DashboardSectionCard({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.onAction,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space16,
              AppTheme.space16,
              AppTheme.space8,
              AppTheme.space8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryContent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space12,
                      vertical: AppTheme.space4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                  child: Text(
                    actionLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.border.withValues(alpha: 0.5)),
          child,
        ],
      ),
    );
  }
}

/// Emplacement d'un graphique en cours de chargement.
class DashboardLoadingCard extends StatelessWidget {
  final double height;
  const DashboardLoadingCard({super.key, this.height = 300});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: SizedBox(
        height: height,
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

/// Barre de chargement dans un bloc de liste.
class DashboardLinearLoading extends StatelessWidget {
  const DashboardLinearLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.space16),
      child: LinearProgressIndicator(
        backgroundColor: AppTheme.surfaceVariant,
        valueColor: AlwaysStoppedAnimation(AppTheme.primaryContent),
      ),
    );
  }
}

/// Liste vide d'un bloc.
class DashboardEmptyMessage extends StatelessWidget {
  final String message;
  const DashboardEmptyMessage(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.space16),
      child: Text(message, style: TextStyle(color: AppTheme.textTertiary)),
    );
  }
}

/// Petite métrique « libellé / valeur » des cartes site et technicien.
class DashboardMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const DashboardMetric(this.label, this.value, {super.key, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
