/// Périmètre d'une requête de statistiques — miroir de `StatsQuery` côté API.
/// Clé des providers `family` : égalité par valeur.
class StatsQuery {
  /// Les N derniers jours, aujourd'hui compris. Ignoré si [from] ou [to] est fixé.
  final int? periodDays;

  /// Première journée incluse.
  final DateTime? from;

  /// Dernière journée **incluse**.
  final DateTime? to;

  /// Restreint à un technicien (ID utilisateur). Ignoré par `/api/personal`.
  final String? technicianId;

  /// Restreint à un site (nom).
  final String? site;

  const StatsQuery({
    this.periodDays,
    this.from,
    this.to,
    this.technicianId,
    this.site,
  });

  /// Toute la base (ou tout l'historique du technicien / du site).
  const StatsQuery.allTime({this.technicianId, this.site})
      : periodDays = null,
        from = null,
        to = null;

  StatsQuery copyWith({String? technicianId, String? site}) => StatsQuery(
        periodDays: periodDays,
        from: from,
        to: to,
        technicianId: technicianId ?? this.technicianId,
        site: site ?? this.site,
      );

  Map<String, dynamic> toQueryParameters() {
    String day(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return {
      if (from != null) 'from': day(from!),
      if (to != null) 'to': day(to!),
      if (from == null && to == null && periodDays != null) 'period': periodDays,
      if (technicianId != null) 'technicienId': technicianId,
      if (site != null) 'site': site,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is StatsQuery &&
      other.periodDays == periodDays &&
      other.from == from &&
      other.to == to &&
      other.technicianId == technicianId &&
      other.site == site;

  @override
  int get hashCode => Object.hash(periodDays, from, to, technicianId, site);
}
