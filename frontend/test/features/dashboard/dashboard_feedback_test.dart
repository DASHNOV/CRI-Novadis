import 'package:flutter_test/flutter_test.dart';
import 'package:novadis_cri/features/dashboard/widgets/kpi_card_widget.dart';
import 'package:novadis_cri/features/dashboard/widgets/time_evolution_chart_widget.dart';
import 'package:novadis_cri/models/site_stats.dart';

/// Retours du 2026-09-25 sur les captures du dashboard.
void main() {
  test('tendance : entier au-delà de 100 %, virgule décimale sinon', () {
    expect(formatTrendPercent(366.666), '367 %');
    expect(formatTrendPercent(-12.34), '12,3 %');
    expect(formatTrendPercent(100), '100 %');
  });

  group('étiquettes de l\'axe des X', () {
    test('la dernière est toujours affichée, sans voisine collée', () {
      // Trimestre par semaine : 14 points, pas de 3.
      const points = 14;
      final step = labelStep(points);
      final shown = [for (var i = 0; i < points; i++) if (showLabelAt(i, points, step)) i];
      expect(shown.last, points - 1);
      for (var k = 1; k < shown.length; k++) {
        expect(shown[k] - shown[k - 1], step);
      }
      expect(shown.length, lessThanOrEqualTo(6));
    });

    test('7 points ou moins : toutes les étiquettes', () {
      expect([for (var i = 0; i < 7; i++) showLabelAt(i, 7, labelStep(7))], everyElement(isTrue));
    });
  });

  test('origine de la position d\'un site', () {
    final fromCri = SiteStats.fromJson({
      'siteNom': 'Libre',
      'totalInterventions': 1,
      'latitude': 47.2,
      'longitude': -1.5,
      'localisationSource': 'cri',
    });
    expect(fromCri.isLocatedFromCri, isTrue);
    expect(SiteStats.fromJson({'siteNom': 'X', 'totalInterventions': 1}).isLocatedFromCri, isFalse);
  });
}
