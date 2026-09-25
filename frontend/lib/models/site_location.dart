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

/// Bilan de `POST /api/sites/geocode`.
class GeocodingSummary {
  final int traites;
  final int localises;
  final int aVerifier;
  final int sansAdresse;
  final int adressesCriTraitees;
  final int adressesCriLocalisees;

  const GeocodingSummary({
    this.traites = 0,
    this.localises = 0,
    this.aVerifier = 0,
    this.sansAdresse = 0,
    this.adressesCriTraitees = 0,
    this.adressesCriLocalisees = 0,
  });

  factory GeocodingSummary.fromJson(Map<String, dynamic> json) => GeocodingSummary(
        traites: json['traites'] as int? ?? 0,
        localises: json['localises'] as int? ?? 0,
        aVerifier: json['aVerifier'] as int? ?? 0,
        sansAdresse: json['sansAdresse'] as int? ?? 0,
        adressesCriTraitees: json['adressesCriTraitees'] as int? ?? 0,
        adressesCriLocalisees: json['adressesCriLocalisees'] as int? ?? 0,
      );

  /// Phrase affichée après la passe.
  String get message {
    if (traites == 0 && adressesCriTraitees == 0) {
      return 'Rien à localiser : tout est déjà à jour.';
    }
    final parts = [
      if (traites > 0) '$localises / $traites sites du référentiel localisés',
      if (aVerifier > 0) '$aVerifier à vérifier',
      if (sansAdresse > 0) '$sansAdresse sans adresse',
      if (adressesCriTraitees > 0)
        '$adressesCriLocalisees / $adressesCriTraitees adresses de CRI localisées',
    ];
    return parts.join(' · ');
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
