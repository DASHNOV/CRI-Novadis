import 'package:flutter/material.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';

/// Configuration des couleurs et styles pour les graphiques
class ChartConfig {
  // Palette de couleurs pour les barres
  static const List<Color> barColors = [
    Color(0xFF2563EB), // Bleu primary
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFF6366F1), // Indigo accent
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEC4899), // Rose
    Color(0xFF84CC16), // Lime
  ];

  // Couleurs des lignes
  static const Color primaryLineColor = Color(0xFF2563EB);

  // Dimensions
  static const double lineWidth = 2.5;
  static const double dotRadius = 3.5;

  // Animation
  static const Duration animationDuration = Duration(milliseconds: 800);
  static const Curve animationCurve = Curves.easeInOut;

  // Style du titre
  static TextStyle get chartTitleStyle => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppTheme.textPrimary,
  );

  static TextStyle get chartSubtitleStyle => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppTheme.textTertiary,
  );

  // Couleurs des KPI cards
  static const Map<String, Color> kpiColors = {
    'interventions': Color(0xFF2563EB),
  };

  // Obtenir une couleur de la palette
  static Color getBarColor(int index) {
    return barColors[index % barColors.length];
  }

  // Formater les valeurs des axes
  static String formatAxisValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toInt().toString();
  }
}
