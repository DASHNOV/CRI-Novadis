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
    );
  }

  static Map<String, int>? _parseMap(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
    }
    return null;
  }

  String get dureeMoyenneFormatee {
    if (dureeMoyenneMinutes == null) return '-';
    final h = dureeMoyenneMinutes! ~/ 60;
    final m = (dureeMoyenneMinutes! % 60).round();
    if (h > 0) return '${h}h ${m}min';
    return '${m}min';
  }
}
