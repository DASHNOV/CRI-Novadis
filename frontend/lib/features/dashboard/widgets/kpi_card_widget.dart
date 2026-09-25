import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/core/theme/responsive.dart';

/// Widget de carte KPI – design moderne inspiré Linear/Stripe
/// Variation affichée à côté de la flèche : valeur absolue, virgule décimale,
/// entier au-delà de 100 % (« 367 % » plutôt que « 366.7% »).
String formatTrendPercent(double value) {
  final abs = value.abs();
  final text = abs >= 100 ? abs.toStringAsFixed(0) : abs.toStringAsFixed(1);
  return '${text.replaceAll('.', ',')} %';
}

class KpiCard extends StatefulWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final double? trendValue;
  final bool? trendPositive;
  final bool isLoading;
  final VoidCallback? onTap;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.iconColor,
    this.trendValue,
    this.trendPositive,
    this.isLoading = false,
    this.onTap,
  });

  @override
  State<KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<KpiCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppTheme.animFast,
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: _isHovered
                ? AppTheme.border
                : AppTheme.border.withValues(alpha: 0.5),
          ),
          boxShadow: _isHovered ? AppTheme.shadowMd : AppTheme.shadowSm,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: widget.isLoading
                  ? _buildShimmerSkeleton()
                  : _buildContent(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final columns = Responsive.kpiColumns(context);
    final isMobile = columns == 1;

    if (isMobile) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              color: widget.iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Icon(widget.icon, color: widget.iconColor, size: 24),
          ),
          const SizedBox(width: AppTheme.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.value,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                        fontSize: 26,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (widget.trendValue != null) _buildTrendIndicator(),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  widget.title,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle!,
                    style: TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    // Original vertical layout for multi-column grids (Tablet/Desktop)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space8),
              decoration: BoxDecoration(
                color: widget.iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Icon(widget.icon, color: widget.iconColor, size: 20),
            ),
            if (widget.trendValue != null) _buildTrendIndicator(),
          ],
        ),
        const Spacer(),
        Text(
          widget.value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            fontSize: 28,
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AppTheme.space4),
        Text(
          widget.title,
          style: TextStyle(
            color: AppTheme.textTertiary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            widget.subtitle!,
            style: TextStyle(
              color: AppTheme.textTertiary,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildTrendIndicator() {
    final isPositive = widget.trendPositive ?? (widget.trendValue! > 0);
    final color = isPositive ? AppTheme.success : AppTheme.error;
    final bgColor = isPositive ? AppTheme.successLight : AppTheme.errorLight;
    final iconData =
        isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            formatTrendPercent(widget.trendValue!),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerSkeleton() {
    final columns = Responsive.kpiColumns(context);
    final isMobile = columns == 1;

    if (isMobile) {
      return Shimmer.fromColors(
        baseColor: AppTheme.surfaceVariant,
        highlightColor: AppTheme.surface,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
            ),
            const SizedBox(width: AppTheme.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 60, height: 26, color: AppTheme.surfaceVariant),
                  const SizedBox(height: AppTheme.space8),
                  Container(width: 100, height: 12, color: AppTheme.surfaceVariant),
                  const SizedBox(height: AppTheme.space4),
                  Container(width: 80, height: 10, color: AppTheme.surfaceVariant),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Shimmer.fromColors(
      baseColor: AppTheme.surfaceVariant,
      highlightColor: AppTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
          ),
          const Spacer(),
          Container(
            width: 80,
            height: 28,
            margin: const EdgeInsets.only(bottom: AppTheme.space8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
          ),
          Container(
            width: 60,
            height: 12,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget pour afficher une grille de KPIs
class KpiGrid extends StatelessWidget {
  final List<KpiCard> cards;
  final int crossAxisCount;

  const KpiGrid({super.key, required this.cards, this.crossAxisCount = 2});

  @override
  Widget build(BuildContext context) {
    final columns = Responsive.kpiColumns(context);

    if (columns == 1) {
      return Column(
        children: cards.asMap().entries.map((entry) {
          final isLast = entry.key == cards.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : AppTheme.space16),
            child: entry.value,
          );
        }).toList(),
      );
    }

    final aspectRatio = columns >= 4 ? 1.5 : 1.3;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: AppTheme.space16,
        mainAxisSpacing: AppTheme.space16,
        childAspectRatio: aspectRatio,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        return cards[index];
      },
    );
  }
}
