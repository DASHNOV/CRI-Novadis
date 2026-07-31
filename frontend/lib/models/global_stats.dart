/// Statistiques globales (admin uniquement)
class GlobalStats {
  final int totalCeMois;
  final int totalSignes;
  final int totalEnAttente;
  final int techniciensActifs;
  final double? dureeMoyenneMinutes;
  final int totalProjets;
  final int totalServices;
  final int totalResolu;
  final int totalNonResolu;
  final int totalRecurrenceRequise;
  final Map<String, int>? repartitionParVille;

  const GlobalStats({
    required this.totalCeMois,
    required this.totalSignes,
    required this.totalEnAttente,
    required this.techniciensActifs,
    this.dureeMoyenneMinutes,
    this.totalProjets = 0,
    this.totalServices = 0,
    this.totalResolu = 0,
    this.totalNonResolu = 0,
    this.totalRecurrenceRequise = 0,
    this.repartitionParVille,
  });

  factory GlobalStats.fromJson(Map<String, dynamic> json) {
    return GlobalStats(
      totalCeMois: json['totalCeMois'] ?? 0,
      totalSignes: json['totalSignes'] ?? 0,
      totalEnAttente: json['totalEnAttente'] ?? 0,
      techniciensActifs: json['techniciensActifs'] ?? 0,
      dureeMoyenneMinutes: (json['dureeMoyenneMinutes'] as num?)?.toDouble(),
      totalProjets: json['totalProjets'] ?? 0,
      totalServices: json['totalServices'] ?? 0,
      totalResolu: json['totalResolu'] ?? 0,
      totalNonResolu: json['totalNonResolu'] ?? 0,
      totalRecurrenceRequise: json['totalRecurrenceRequise'] ?? 0,
      repartitionParVille: _parseMap(json['repartitionParVille']),
    );
  }

  factory GlobalStats.empty() {
    return const GlobalStats(
      totalCeMois: 0,
      totalSignes: 0,
      totalEnAttente: 0,
      techniciensActifs: 0,
    );
  }

  static Map<String, int>? _parseMap(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
    }
    return null;
  }

  /// Pourcentage de CRI signés
  double get signedPercentage {
    final total = totalSignes + totalEnAttente;
    if (total == 0) return 0;
    return (totalSignes / total) * 100;
  }

  /// Durée moyenne formatée
  String get dureeMoyenneFormatee {
    if (dureeMoyenneMinutes == null) return '-';
    final h = dureeMoyenneMinutes! ~/ 60;
    final m = (dureeMoyenneMinutes! % 60).round();
    if (h > 0) return '${h}h ${m}min';
    return '${m}min';
  }
}
