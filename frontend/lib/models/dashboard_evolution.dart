/// Courbe d'évolution du nombre d'interventions (`/stats/evolution`).
class DashboardEvolution {
  /// `day`, `week` (lundi) ou `month`, choisi par l'API selon la durée couverte.
  final String granularity;
  final List<EvolutionPoint> points;

  const DashboardEvolution({required this.granularity, required this.points});

  factory DashboardEvolution.fromJson(Map<String, dynamic> json) {
    return DashboardEvolution(
      granularity: json['granularity'] as String? ?? 'day',
      points: (json['points'] as List? ?? const [])
          .map((p) => EvolutionPoint.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Libellé de l'unité, pour les titres (« par jour »…).
  String get granularityLabel => switch (granularity) {
        'week' => 'par semaine',
        'month' => 'par mois',
        _ => 'par jour',
      };
}

class EvolutionPoint {
  final DateTime debut;
  final String label;
  final int total;
  final int services;
  final int projets;
  final int resolu;

  const EvolutionPoint({
    required this.debut,
    required this.label,
    required this.total,
    this.services = 0,
    this.projets = 0,
    this.resolu = 0,
  });

  factory EvolutionPoint.fromJson(Map<String, dynamic> json) {
    return EvolutionPoint(
      debut: DateTime.parse(json['debut'] as String),
      label: json['label'] as String? ?? '',
      total: json['total'] as int? ?? 0,
      services: json['services'] as int? ?? 0,
      projets: json['projets'] as int? ?? 0,
      resolu: json['resolu'] as int? ?? 0,
    );
  }
}
