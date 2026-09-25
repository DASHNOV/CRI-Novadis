/// Statistiques agrégées par site (depuis l'API backend)
class SiteStats {
  final int? siteID;
  final String siteNom;
  final String? clientNom;
  final String? ville;
  final int totalInterventions;
  final double? dureeMoyenneMinutes;
  final int totalServices;
  final int totalProjets;
  final int totalResolu;
  final int totalNonResolu;
  final int totalRecurrenceRequise;
  final double tauxRecurrence;
  final String? topCategorie;
  final int topCategorieCount;
  final DateTime? derniereIntervention;
  final int techniciensDistincts;
  final Map<String, int>? repartitionParCategorie;

  /// Coordonnées WGS84 (`null` : site en saisie libre, non géocodé ou à vérifier).
  final double? latitude;
  final double? longitude;

  /// `housenumber`, `street`, `locality`, `municipality` (centre de la commune).
  final String? geocodagePrecision;

  /// `referentiel` (site normalisé) ou `cri` (adresse saisie dans le CRI).
  final String? localisationSource;

  const SiteStats({
    this.siteID,
    required this.siteNom,
    this.clientNom,
    this.ville,
    required this.totalInterventions,
    this.dureeMoyenneMinutes,
    this.totalServices = 0,
    this.totalProjets = 0,
    this.totalResolu = 0,
    this.totalNonResolu = 0,
    this.totalRecurrenceRequise = 0,
    this.tauxRecurrence = 0,
    this.topCategorie,
    this.topCategorieCount = 0,
    this.derniereIntervention,
    this.techniciensDistincts = 0,
    this.repartitionParCategorie,
    this.latitude,
    this.longitude,
    this.geocodagePrecision,
    this.localisationSource,
  });

  factory SiteStats.fromJson(Map<String, dynamic> json) {
    return SiteStats(
      siteID: json['siteID'] as int?,
      siteNom: json['siteNom'] ?? '',
      clientNom: json['clientNom'] as String?,
      ville: json['ville'] as String?,
      totalInterventions: json['totalInterventions'] ?? 0,
      dureeMoyenneMinutes: (json['dureeMoyenneMinutes'] as num?)?.toDouble(),
      totalServices: json['totalServices'] ?? 0,
      totalProjets: json['totalProjets'] ?? 0,
      totalResolu: json['totalResolu'] ?? 0,
      totalNonResolu: json['totalNonResolu'] ?? 0,
      totalRecurrenceRequise: json['totalRecurrenceRequise'] ?? 0,
      tauxRecurrence: (json['tauxRecurrence'] as num?)?.toDouble() ?? 0,
      topCategorie: json['topCategorie'] as String?,
      topCategorieCount: json['topCategorieCount'] ?? 0,
      derniereIntervention: json['derniereIntervention'] != null
          ? DateTime.tryParse(json['derniereIntervention'])
          : null,
      techniciensDistincts: json['techniciensDistincts'] ?? 0,
      repartitionParCategorie: _parseMap(json['repartitionParCategorie']),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      geocodagePrecision: json['geocodagePrecision'] as String?,
      localisationSource: json['localisationSource'] as String?,
    );
  }

  static Map<String, int>? _parseMap(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
    }
    return null;
  }

  bool get hasLocation => latitude != null && longitude != null;

  /// Position approximative : seule la commune a été reconnue.
  bool get isApproximateLocation => geocodagePrecision == 'municipality';

  /// Placé d'après l'adresse saisie dans un CRI (site hors référentiel).
  bool get isLocatedFromCri => localisationSource == 'cri';

  String get dureeMoyenneFormatee {
    if (dureeMoyenneMinutes == null) return '-';
    final h = dureeMoyenneMinutes! ~/ 60;
    final m = (dureeMoyenneMinutes! % 60).round();
    if (h > 0) return '${h}h ${m}min';
    return '${m}min';
  }
}
