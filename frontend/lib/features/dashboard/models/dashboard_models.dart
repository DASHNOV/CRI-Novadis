// Modèles de données pour le Dashboard

/// Énumération des périodes de filtre
enum DashboardPeriod {
  day('Jour', 1),
  week('Semaine', 7),
  month('Mois', 30),
  quarter('Trimestre', 90),
  year('Année', 365),

  /// Plage choisie par l'utilisateur (`customRangeProvider`) ; [days] inutilisé.
  custom('Personnalisée', 0);

  final String label;
  final int days;

  /// [days] derniers jours, aujourd'hui compris : bornes calculées par l'API
  /// (`StatsFilter.LastDays`).
  const DashboardPeriod(this.label, this.days);

  /// Formate le label de la période
  String get periodLabel {
    switch (this) {
      case DashboardPeriod.day:
        return "Aujourd'hui";
      case DashboardPeriod.week:
        return '7 derniers jours';
      case DashboardPeriod.month:
        return '30 derniers jours';
      case DashboardPeriod.quarter:
        return '90 derniers jours';
      case DashboardPeriod.year:
        return '365 derniers jours';
      case DashboardPeriod.custom:
        return 'Plage personnalisée';
    }
  }
}

/// Modèle de technicien pour les statistiques
class TechnicianModel {
  final String id;
  final String name;

  /// `null` si inconnue : ne jamais la reconstruire à partir du nom.
  final String? email;
  final String? role;

  const TechnicianModel({
    required this.id,
    required this.name,
    this.email,
    this.role,
  });

  /// Depuis `/api/global/technicians` (`UserDto`).
  factory TechnicianModel.fromJson(Map<String, dynamic> json) {
    final name = '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim();
    return TechnicianModel(
      id: json['id'] as String,
      name: name.isEmpty ? (json['email'] as String? ?? '') : name,
      email: json['email'] as String?,
      role: json['role'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TechnicianModel &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.role == role;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ email.hashCode ^ role.hashCode;
  }
}
