import 'package:flutter_test/flutter_test.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/features/dashboard/widgets/sites_map.dart';
import 'package:novadis_cri/models/site_stats.dart';

void main() {
  test('couleur : vert < 10 %, orange 10–20 %, rouge au-delà', () {
    expect(recurrenceColor(0), AppTheme.success);
    expect(recurrenceColor(9.9), AppTheme.success);
    expect(recurrenceColor(10), AppTheme.warning);
    expect(recurrenceColor(20), AppTheme.warning);
    expect(recurrenceColor(20.1), AppTheme.error);
  });

  test('taille : surface proportionnelle au volume, bornée', () {
    expect(markerDiameter(0, 100), 16);
    expect(markerDiameter(100, 100), 44);
    expect(markerDiameter(25, 100), 16 + 28 * 0.5); // √(25/100) = 0,5
    expect(markerDiameter(5, 0), 16);
  });

  test('SiteStats lit les coordonnées et la précision', () {
    final located = SiteStats.fromJson({
      'siteNom': 'A',
      'totalInterventions': 2,
      'latitude': 45.75,
      'longitude': 4.85,
      'geocodagePrecision': 'municipality',
    });
    expect(located.hasLocation, isTrue);
    expect(located.isApproximateLocation, isTrue);

    final free = SiteStats.fromJson({'siteNom': 'Saisie libre', 'totalInterventions': 1});
    expect(free.hasLocation, isFalse);
  });
}
