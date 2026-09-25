/// Statistiques globales (admin uniquement)
class GlobalStats {
  /// CRI de la période demandée.
  final int totalInterventions;
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

  /// Période précédente de même durée (`null` sans période).
  final PeriodComparison? periodePrecedente;

  const GlobalStats({
    required this.totalInterventions,
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
    this.periodePrecedente,
  });

  factory GlobalStats.fromJson(Map<String, dynamic> json) {
    return GlobalStats(
      // `totalCeMois` : ancien nom, renvoyé par les API antérieures.
      totalInterventions:
          json['totalInterventions'] ?? json['totalCeMois'] ?? 0,
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
      periodePrecedente: json['periodePrecedente'] is Map<String, dynamic>
          ? PeriodComparison.fromJson(json['periodePrecedente'])
          : null,
    );
  }

  factory GlobalStats.empty() {
    return const GlobalStats(
      totalInterventions: 0,
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

  /// Variation en % par rapport à la période précédente, `null` si rien à
  /// comparer (pas de période, ou 0 sur la période précédente).
  static double? trend(num? current, num? previous) {
    if (current == null || previous == null || previous == 0) return null;
    return (current - previous) / previous * 100;
  }

  double? get interventionsTrend =>
      trend(totalInterventions, periodePrecedente?.totalInterventions);
  double? get resoluTrend => trend(totalResolu, periodePrecedente?.totalResolu);
  double? get recurrenceTrend =>
      trend(totalRecurrenceRequise, periodePrecedente?.totalRecurrenceRequise);
}

/// Chiffres clés d'une période de comparaison.
class PeriodComparison {
  final int totalInterventions;
  final int totalResolu;
  final double? dureeMoyenneMinutes;
  final int totalRecurrenceRequise;

  const PeriodComparison({
    required this.totalInterventions,
    required this.totalResolu,
    this.dureeMoyenneMinutes,
    required this.totalRecurrenceRequise,
  });

  factory PeriodComparison.fromJson(Map<String, dynamic> json) {
    return PeriodComparison(
      totalInterventions: json['totalInterventions'] ?? 0,
      totalResolu: json['totalResolu'] ?? 0,
      dureeMoyenneMinutes: (json['dureeMoyenneMinutes'] as num?)?.toDouble(),
      totalRecurrenceRequise: json['totalRecurrenceRequise'] ?? 0,
    );
  }
}
