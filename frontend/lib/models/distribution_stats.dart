/// Statistiques de distribution croisées (depuis l'API backend)
class DistributionStats {
  final List<CrossTabEntry>? categorieParSite;
  final List<CrossTabEntry>? technicienParSite;
  final List<EvolutionMensuelleEntry>? evolutionMensuelle;
  final Map<String, int>? repartitionParVille;
  final Map<String, int>? repartitionParCategorie;

  const DistributionStats({
    this.categorieParSite,
    this.technicienParSite,
    this.evolutionMensuelle,
    this.repartitionParVille,
    this.repartitionParCategorie,
  });

  factory DistributionStats.fromJson(Map<String, dynamic> json) {
    return DistributionStats(
      categorieParSite: (json['categorieParSite'] as List?)
          ?.map((e) => CrossTabEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      technicienParSite: (json['technicienParSite'] as List?)
          ?.map((e) => CrossTabEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      evolutionMensuelle: (json['evolutionMensuelle'] as List?)
          ?.map((e) =>
              EvolutionMensuelleEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      repartitionParVille: _parseMap(json['repartitionParVille']),
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
}

class CrossTabEntry {
  final String ligne;
  final String colonne;
  final int valeur;

  const CrossTabEntry({
    required this.ligne,
    required this.colonne,
    required this.valeur,
  });

  factory CrossTabEntry.fromJson(Map<String, dynamic> json) {
    return CrossTabEntry(
      ligne: json['ligne'] ?? '',
      colonne: json['colonne'] ?? '',
      valeur: json['valeur'] ?? 0,
    );
  }
}

class EvolutionMensuelleEntry {
  final int annee;
  final int mois;
  final String label;
  final int totalInterventions;
  final int services;
  final int projets;
  final int resolu;
  final double? dureeMoyenneMinutes;

  const EvolutionMensuelleEntry({
    required this.annee,
    required this.mois,
    required this.label,
    required this.totalInterventions,
    this.services = 0,
    this.projets = 0,
    this.resolu = 0,
    this.dureeMoyenneMinutes,
  });

  factory EvolutionMensuelleEntry.fromJson(Map<String, dynamic> json) {
    return EvolutionMensuelleEntry(
      annee: json['annee'] ?? 0,
      mois: json['mois'] ?? 0,
      label: json['label'] ?? '',
      totalInterventions: json['totalInterventions'] ?? 0,
      services: json['services'] ?? 0,
      projets: json['projets'] ?? 0,
      resolu: json['resolu'] ?? 0,
      dureeMoyenneMinutes: (json['dureeMoyenneMinutes'] as num?)?.toDouble(),
    );
  }
}
