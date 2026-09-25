import 'package:flutter_test/flutter_test.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/features/dashboard/models/map_site.dart';
import 'package:novadis_cri/features/dashboard/widgets/sites_map.dart';
import 'package:novadis_cri/models/site_location.dart';
import 'package:novadis_cri/models/site_stats.dart';

SiteLocation _ref(int numero, String nom, {String? adresse, String? precision}) => SiteLocation(
      numero: numero,
      nomDuSite: nom,
      adresse: adresse,
      codePostal: '69001',
      ville: 'Lyon',
      latitude: 45.0 + numero / 100,
      longitude: 4.0,
      geocodagePrecision: precision,
    );

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
    expect(SiteStats.fromJson({'siteNom': 'Libre', 'totalInterventions': 1}).hasLocation, isFalse);
  });

  group('points de la carte', () {
    test('tous les sites du référentiel, activité fusionnée par numéro ou par nom', () {
      final stats = [
        const SiteStats(siteID: 1, siteNom: 'Agence', totalInterventions: 5),
        const SiteStats(siteNom: 'depot nord ', totalInterventions: 2), // saisie libre, même nom
        const SiteStats(siteNom: 'Libre', totalInterventions: 1, latitude: 47.2, longitude: -1.5),
        const SiteStats(siteNom: 'Nulle part', totalInterventions: 1), // ni référentiel ni coordonnées
      ];
      final referentiel = [_ref(1, 'Agence'), _ref(2, 'Dépôt Nord'), _ref(3, 'Depot Nord'), _ref(4, 'Sans CRI')];

      final points = buildMapSites(stats, referentiel);
      final byName = {for (final p in points) p.name: p};

      expect(byName['Agence']!.stats!.totalInterventions, 5);
      expect(byName['depot nord ']!.stats, isNotNull); // rapproché de « Depot Nord »
      expect(byName['Libre']!.latitude, 47.2);
      expect(byName.containsKey('Nulle part'), isFalse);
      expect(byName['Sans CRI']!.stats, isNull); // gris
      expect(byName['Dépôt Nord']!.stats, isNull); // accent différent : autre site
      expect(points, hasLength(5));
    });

    test('itinéraire : coordonnées, ou adresse si la position n\'est que la commune', () {
      final precise = MapSite(name: 'A', latitude: 45.1, longitude: 4.2, adresse: '1 rue X');
      expect(
        precise.directionsUri.toString(),
        'https://www.google.com/maps/dir/?api=1&destination=45.1%2C4.2',
      );

      final approx = MapSite(
        name: 'B',
        latitude: 45.7,
        longitude: 4.8,
        adresse: '3 rue Y',
        codePostal: '69001',
        ville: 'Lyon',
        precision: 'municipality',
      );
      expect(approx.directionsUri.queryParameters['destination'], '3 rue Y, 69001 Lyon');
    });

    test('égalité par valeur (sélection conservée entre deux affichages)', () {
      expect(
        const MapSite(name: 'A', latitude: 1, longitude: 2),
        const MapSite(name: 'A', latitude: 1, longitude: 2),
      );
    });
  });
}
