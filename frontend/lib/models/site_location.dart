/// Site du référentiel placé sur la carte (`GET /api/sites/map`).
class SiteLocation {
  final int numero;
  final String nomDuSite;
  final String? adresse;
  final String? ville;
  final String? codePostal;
  final double latitude;
  final double longitude;
  final String? geocodagePrecision;

  const SiteLocation({
    required this.numero,
    required this.nomDuSite,
    this.adresse,
    this.ville,
    this.codePostal,
    required this.latitude,
    required this.longitude,
    this.geocodagePrecision,
  });

  factory SiteLocation.fromJson(Map<String, dynamic> json) {
    return SiteLocation(
      numero: json['numero'] as int,
      nomDuSite: json['nomDuSite'] as String? ?? '',
      adresse: json['adresse'] as String?,
      ville: json['ville'] as String?,
      codePostal: json['codePostal'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      geocodagePrecision: json['geocodagePrecision'] as String?,
    );
  }
}

/// Réponse de `GET /api/sites/map`.
class SitesMapData {
  final List<SiteLocation> sites;

  /// Sites du référentiel encore sans coordonnées.
  final int nonLocalises;

  const SitesMapData({required this.sites, required this.nonLocalises});

  factory SitesMapData.fromJson(Map<String, dynamic> json) {
    return SitesMapData(
      sites: (json['sites'] as List? ?? const [])
          .map((e) => SiteLocation.fromJson(e as Map<String, dynamic>))
          .toList(),
      nonLocalises: json['nonLocalises'] as int? ?? 0,
    );
  }
}
