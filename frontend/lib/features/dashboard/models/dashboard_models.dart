// Modèles de données pour le Dashboard

import 'package:novadis_cri/core/utils/duration_format.dart';

/// Énumération des périodes de filtre
enum DashboardPeriod {
  day('Jour', 1),
  week('Semaine', 7),
  month('Mois', 30);

  final String label;
  final int days;

  const DashboardPeriod(this.label, this.days);

  /// Début de la période, **inclus** : minuit, `days - 1` jours avant aujourd'hui
  /// (« 7 derniers jours » = aujourd'hui et les 6 jours précédents).
  /// Les dates d'intervention sont saisies à la journée (minuit) : une fenêtre
  /// glissante à l'heure près excluait la première journée ou le 1er du mois.
  DateTime get startDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - (days - 1));
  }

  /// Fin de la période, **exclue** : minuit ce soir.
  DateTime get endDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  /// Période précédente de même durée (pour les tendances) : `[début - days, début[`.
  DateTime get previousStartDate {
    final start = startDate;
    return DateTime(start.year, start.month, start.day - days);
  }

  DateTime get previousEndDate => startDate;

  /// `true` si [date] tombe dans la période : `[startDate, endDate[`.
  bool contains(DateTime date) =>
      !date.isBefore(startDate) && date.isBefore(endDate);

  /// `true` si [date] tombe dans la période précédente.
  bool previousContains(DateTime date) =>
      !date.isBefore(previousStartDate) && date.isBefore(previousEndDate);

  /// Nombre de jours affichés par la courbe d'évolution : au moins 7, une
  /// courbe d'un seul point (« Jour ») ne montrant rien.
  int get evolutionDays => days < 7 ? 7 : days;

  /// Formate le label de la période
  String get periodLabel {
    switch (this) {
      case DashboardPeriod.day:
        return "Aujourd'hui";
      case DashboardPeriod.week:
        return '7 derniers jours';
      case DashboardPeriod.month:
        return '30 derniers jours';
    }
  }
}

/// Données des KPIs du dashboard
class DashboardKpis {
  final int totalInterventions;
  final int activeSites;
  final double averageDurationMinutes;
  final double completionRate;
  final double? previousCompletionRate;

  /// Interventions de la période terminées : service « Résolu », projet « Terminé ».
  final int realizedInterventions;

  /// Interventions de la période non terminées : `total - réalisées`.
  final int pendingInterventions;

  const DashboardKpis({
    required this.totalInterventions,
    required this.activeSites,
    required this.averageDurationMinutes,
    required this.completionRate,
    this.previousCompletionRate,
    this.realizedInterventions = 0,
    this.pendingInterventions = 0,
  });

  /// Durée moyenne formatée
  String get formattedAverageDuration =>
      formatDurationMinutes(averageDurationMinutes);

  /// Calcule le changement de tendance
  double? get completionRateTrend {
    if (previousCompletionRate == null || previousCompletionRate == 0) {
      return null;
    }
    return completionRate - previousCompletionRate!;
  }

  /// Valeurs par défaut (état vide)
  factory DashboardKpis.empty() {
    return const DashboardKpis(
      totalInterventions: 0,
      activeSites: 0,
      averageDurationMinutes: 0,
      completionRate: 0,
    );
  }
}

/// Données pour le graphique d'évolution temporelle
class TimeEvolutionData {
  final DateTime date;
  final int count;
  final String label;

  const TimeEvolutionData({
    required this.date,
    required this.count,
    required this.label,
  });
}

/// Données pour le graphique de distribution par type
class TypeDistributionData {
  final String type;
  final int count;
  final double percentage;

  const TypeDistributionData({
    required this.type,
    required this.count,
    required this.percentage,
  });
}

/// Données pour le top sites
class TopSiteData {
  final String siteId;
  final String siteName;
  final String clientName;
  final int visitCount;

  const TopSiteData({
    required this.siteId,
    required this.siteName,
    required this.clientName,
    required this.visitCount,
  });
}

/// Données de charge de travail par technicien
class TechnicianWorkloadData {
  final String technicianId;
  final String technicianName;
  final int interventionCount;
  final double totalHours;
  final double completionRate;

  const TechnicianWorkloadData({
    required this.technicianId,
    required this.technicianName,
    required this.interventionCount,
    required this.totalHours,
    required this.completionRate,
  });
}

/// Données complètes du dashboard
class DashboardData {
  final DashboardKpis kpis;
  final List<TimeEvolutionData> timeEvolution;
  final List<TypeDistributionData> typeDistribution;
  final List<TopSiteData> topSites;
  final List<TechnicianWorkloadData> technicianWorkload;
  final List<RecentIntervention> recentInterventions;
  final DateTime lastUpdated;

  const DashboardData({
    required this.kpis,
    required this.timeEvolution,
    required this.typeDistribution,
    required this.topSites,
    required this.technicianWorkload,
    this.recentInterventions = const [],
    required this.lastUpdated,
  });

  factory DashboardData.empty() {
    return DashboardData(
      kpis: DashboardKpis.empty(),
      timeEvolution: [],
      typeDistribution: [],
      topSites: [],
      technicianWorkload: [],
      lastUpdated: DateTime.now(),
    );
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

/// KPIs individuels du technicien
class TechnicianKpis {
  // Volume
  final int assignedInterventions;
  final int completedInterventions;
  final double teamComparison;

  // Performance temporelle
  final double averageDurationMinutes;

  /// Écart de durée moyenne avec l'équipe, en minutes (`null` : non calculé).
  final double? standardDeviation;

  /// Ponctualité en % (`null` : aucune donnée de planning pour la mesurer).
  final double? punctualityRate;

  // Qualité
  final double firstTimeFixRate;
  final double escalationRate;

  const TechnicianKpis({
    required this.assignedInterventions,
    required this.completedInterventions,
    required this.teamComparison,
    required this.averageDurationMinutes,
    this.standardDeviation,
    this.punctualityRate,
    required this.firstTimeFixRate,
    required this.escalationRate,
  });

  String get formattedAverageDuration =>
      formatDurationMinutes(averageDurationMinutes);

  factory TechnicianKpis.empty() {
    return const TechnicianKpis(
      assignedInterventions: 0,
      completedInterventions: 0,
      teamComparison: 0,
      averageDurationMinutes: 0,
      firstTimeFixRate: 0,
      escalationRate: 0,
    );
  }
}

/// Données pour le radar de compétences
class SkillRadarData {
  final String category;
  final int count;
  final double normalizedValue;

  const SkillRadarData({
    required this.category,
    required this.count,
    required this.normalizedValue,
  });
}

/// Données pour la courbe de charge
class WorkloadData {
  final DateTime weekStart;
  final double totalHours;
  final int interventionCount;
  final String weekLabel;

  const WorkloadData({
    required this.weekStart,
    required this.totalHours,
    this.interventionCount = 0,
    required this.weekLabel,
  });
}

/// Données des statistiques technicien
class TechnicianStatsData {
  final TechnicianKpis kpis;
  final List<SkillRadarData> skillsRadar;
  final List<WorkloadData> workloadCurve;
  final List<TopSiteData> topSites;
  final String? topCategory;

  const TechnicianStatsData({
    required this.kpis,
    required this.skillsRadar,
    required this.workloadCurve,
    this.topSites = const [],
    this.topCategory,
  });

  factory TechnicianStatsData.empty() {
    return TechnicianStatsData(
      kpis: TechnicianKpis.empty(),
      skillsRadar: const [],
      workloadCurve: const [],
    );
  }
}

/// Données de site détaillées
class SiteDetailsData {
  final String siteId;
  final String siteName;
  final String clientName;
  final String? address;
  final int totalInterventions;
  final double? averageResolutionTime;
  final List<SiteInterventionItem> interventionHistory;

  const SiteDetailsData({
    required this.siteId,
    required this.siteName,
    required this.clientName,
    this.address,
    required this.totalInterventions,
    this.averageResolutionTime,
    required this.interventionHistory,
  });
}

/// Élément d'historique d'intervention pour un site
class SiteInterventionItem {
  final String id;
  final DateTime date;
  final String type;
  final String technicianName;
  final String status;
  final String? source;
  final int durationMinutes;

  const SiteInterventionItem({
    required this.id,
    required this.date,
    required this.type,
    required this.technicianName,
    required this.status,
    this.source,
    required this.durationMinutes,
  });
}

/// Modèle pour une intervention récente sur le Dashboard
class RecentIntervention {
  final String id;
  final String technicianName;
  final DateTime date;
  final int durationMinutes;
  final String status;
  final String type;
  final String source; // 'service' ou 'projet'

  const RecentIntervention({
    required this.id,
    required this.technicianName,
    required this.date,
    required this.durationMinutes,
    required this.status,
    required this.type,
    required this.source,
  });
}
