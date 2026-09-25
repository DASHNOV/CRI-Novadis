import 'package:novadis_cri/models/site_location.dart';
import 'package:novadis_cri/models/site_stats.dart';

/// Point de la carte des sites : un site du référentiel et / ou un site ayant de
/// l'activité sur la période ([stats] non nul).
class MapSite {
  final String name;
  final double latitude;
  final double longitude;

  /// Activité sur la période ; `null` : site du référentiel sans CRI (gris).
  final SiteStats? stats;

  final String? adresse;
  final String? codePostal;
  final String? ville;
  final String? precision;

  /// Placé d'après l'adresse saisie dans un CRI (site hors référentiel).
  final bool fromCri;

  const MapSite({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.stats,
    this.adresse,
    this.codePostal,
    this.ville,
    this.precision,
    this.fromCri = false,
  });

  bool get isApproximate => precision == 'municipality';

  // Égalité par valeur : les points sont recalculés à chaque affichage, la
  // sélection doit survivre (surbrillance, recentrage seulement si elle change).
  @override
  bool operator ==(Object other) =>
      other is MapSite &&
      other.name == name &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(name, latitude, longitude);

  /// Clé de rapprochement stats ↔ référentiel : même règle que `SiteNames.Key` côté API.
  static String key(String name) => name.trim().toLowerCase();

  /// Adresse lisible (« 3 rue X, 44000 Nantes »), `null` si inconnue.
  String? get addressLine {
    final city = [codePostal, ville].where((p) => p != null && p.trim().isNotEmpty).join(' ');
    final parts = [adresse, city].where((p) => p != null && p.trim().isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(', ');
  }

  /// Itinéraire Google Maps depuis la position de l'utilisateur. Destination :
  /// les coordonnées, sauf position approximative (centre de commune) avec une
  /// adresse connue — Google la trouvera mieux que le centre de la commune.
  Uri get directionsUri {
    final destination = isApproximate && adresse != null && addressLine != null
        ? addressLine!
        : '$latitude,$longitude';
    return Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': destination,
    });
  }
}

/// Tous les points de la carte : les sites avec activité sur la période (stats,
/// y compris ceux placés via l'adresse du CRI), puis les autres sites du
/// référentiel, sans activité.
List<MapSite> buildMapSites(List<SiteStats> stats, List<SiteLocation> referentiel) {
  final byNumero = {for (final s in referentiel) s.numero: s};
  final byName = {for (final s in referentiel) MapSite.key(s.nomDuSite): s};
  final usedNumeros = <int>{};
  final points = <MapSite>[];

  for (final site in stats) {
    final ref = (site.siteID != null ? byNumero[site.siteID] : null) ??
        byName[MapSite.key(site.siteNom)];
    if (ref != null) usedNumeros.add(ref.numero);
    final lat = site.latitude ?? ref?.latitude;
    final lng = site.longitude ?? ref?.longitude;
    if (lat == null || lng == null) continue;
    points.add(MapSite(
      name: site.siteNom,
      latitude: lat,
      longitude: lng,
      stats: site,
      adresse: ref?.adresse,
      codePostal: ref?.codePostal,
      ville: ref?.ville ?? site.ville,
      precision: site.geocodagePrecision ?? ref?.geocodagePrecision,
      fromCri: site.isLocatedFromCri,
    ));
  }

  for (final ref in referentiel) {
    if (usedNumeros.contains(ref.numero)) continue;
    points.add(MapSite(
      name: ref.nomDuSite,
      latitude: ref.latitude,
      longitude: ref.longitude,
      adresse: ref.adresse,
      codePostal: ref.codePostal,
      ville: ref.ville,
      precision: ref.geocodagePrecision,
    ));
  }
  return points;
}
