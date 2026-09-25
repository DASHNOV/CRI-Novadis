import 'package:novadis_cri/data/models/cri_service_model.dart';
import 'package:novadis_cri/data/models/cri_projet_model.dart';
import 'package:novadis_cri/data/local/tables/cri_service_table.dart';
import 'package:novadis_cri/data/local/tables/cri_projet_table.dart';
import 'package:novadis_cri/features/dashboard/models/dashboard_models.dart';

/// Service de calcul des KPIs du dashboard.
///
/// Toutes les méthodes filtrent par [DashboardPeriod.contains] : bornes
/// `[début, fin[` alignées sur minuit. Ne jamais filtrer avec `isAfter(début)`,
/// qui exclut les interventions datées pile du premier jour (saisies à minuit).
class KpiCalculatorService {
  static const _monthNames = [
    'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
    'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc',
  ];

  /// Service terminé : « Résolu » uniquement (même règle que `TotalResolu` côté API).
  static bool isServiceRealized(CriServiceModel s) =>
      s.resolutionStatus == ResolutionStatus.resolu;

  /// Projet terminé : « Terminé ».
  static bool isProjetRealized(CriProjetModel p) =>
      p.projectStatus == ProjectStatus.termine;

  /// Calcule le nombre total d'interventions
  int calculateTotalInterventions(
    List<CriServiceModel> services,
    List<CriProjetModel> projets,
    DashboardPeriod period,
  ) {
    return services.where((s) => period.contains(s.interventionDate)).length +
        projets.where((p) => period.contains(p.interventionDate)).length;
  }

  /// Interventions terminées sur la période (voir [isServiceRealized]).
  int calculateRealizedInterventions(
    List<CriServiceModel> services,
    List<CriProjetModel> projets,
    DashboardPeriod period,
  ) {
    return services
            .where((s) => period.contains(s.interventionDate) && isServiceRealized(s))
            .length +
        projets
            .where((p) => period.contains(p.interventionDate) && isProjetRealized(p))
            .length;
  }

  /// Calcule le nombre de sites actifs (distincts)
  int calculateActiveSites(
    List<CriServiceModel> services,
    List<CriProjetModel> projets,
    DashboardPeriod period,
  ) {
    return {
      ...services
          .where((s) => period.contains(s.interventionDate))
          .map((s) => s.site),
      ...projets
          .where((p) => period.contains(p.interventionDate))
          .map((p) => p.site),
    }.where((site) => site.isNotEmpty).length;
  }

  /// Durée moyenne en minutes. Les durées nulles sont exclues (non saisies),
  /// comme côté API.
  double calculateAverageDuration(
    List<CriServiceModel> services,
    List<CriProjetModel> projets,
    DashboardPeriod period,
  ) {
    final durations = [
      ...services
          .where((s) => period.contains(s.interventionDate))
          .map((s) => s.interventionDurationMinutes),
      ...projets
          .where((p) => period.contains(p.interventionDate))
          .map((p) => p.durationMinutes),
    ].where((d) => d > 0).toList();

    if (durations.isEmpty) return 0;
    return durations.reduce((a, b) => a + b) / durations.length;
  }

  /// Taux de réalisation en % : réalisées / total sur la période.
  double calculateCompletionRate(
    List<CriServiceModel> services,
    List<CriProjetModel> projets,
    DashboardPeriod period,
  ) {
    final total = calculateTotalInterventions(services, projets, period);
    if (total == 0) return 0;
    return calculateRealizedInterventions(services, projets, period) / total * 100;
  }

  /// Taux de réalisation de la période précédente de même durée.
  double calculatePreviousCompletionRate(
    List<CriServiceModel> services,
    List<CriProjetModel> projets,
    DashboardPeriod period,
  ) {
    final prevServices =
        services.where((s) => period.previousContains(s.interventionDate));
    final prevProjets =
        projets.where((p) => period.previousContains(p.interventionDate));
    final total = prevServices.length + prevProjets.length;
    if (total == 0) return 0;
    final realized = prevServices.where(isServiceRealized).length +
        prevProjets.where(isProjetRealized).length;
    return realized / total * 100;
  }

  /// Calcule la tendance entre deux valeurs
  TrendDirection calculateTrend(double currentValue, double previousValue) {
    if (previousValue == 0) return TrendDirection.neutral;
    final change = currentValue - previousValue;
    if (change > 0.5) return TrendDirection.up;
    if (change < -0.5) return TrendDirection.down;
    return TrendDirection.neutral;
  }

  /// Évolution jour par jour sur [DashboardPeriod.evolutionDays] jours
  /// (au moins 7), jours sans intervention compris.
  List<TimeEvolutionData> calculateTimeEvolution(
    List<CriServiceModel> services,
    List<CriProjetModel> projets,
    DashboardPeriod period,
  ) {
    final end = period.endDate;
    final days = period.evolutionDays;
    final dates = [
      ...services.map((s) => s.interventionDate),
      ...projets.map((p) => p.interventionDate),
    ];

    return List.generate(days, (i) {
      final day = DateTime(end.year, end.month, end.day - days + i);
      final next = DateTime(day.year, day.month, day.day + 1);
      final count =
          dates.where((d) => !d.isBefore(day) && d.isBefore(next)).length;
      return TimeEvolutionData(
        date: day,
        count: count,
        label: '${day.day} ${_monthNames[day.month - 1]}',
      );
    });
  }

  /// Calcule la distribution par type d'intervention (Top 5)
  List<TypeDistributionData> calculateTypeDistribution(
    List<CriServiceModel> services,
    List<CriProjetModel> projets,
    DashboardPeriod period,
  ) {
    final typeCounts = calculateCategoryCounts(services, projets, period);
    final total = typeCounts.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return [];

    final sortedEntries = typeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.take(5).map((entry) {
      return TypeDistributionData(
        type: entry.key,
        count: entry.value,
        percentage: (entry.value / total) * 100,
      );
    }).toList();
  }

  /// Nombre d'interventions par type de demande (service) ou d'intervention (projet).
  Map<String, int> calculateCategoryCounts(
    List<CriServiceModel> services,
    List<CriProjetModel> projets,
    DashboardPeriod period,
  ) {
    final counts = <String, int>{};
    for (final s in services.where((s) => period.contains(s.interventionDate))) {
      counts.update(s.requestType.label, (c) => c + 1, ifAbsent: () => 1);
    }
    for (final p in projets.where((p) => period.contains(p.interventionDate))) {
      counts.update(p.interventionType.label, (c) => c + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  /// Calcule le top 20 des sites les plus visités
  List<TopSiteData> calculateTopSites(
    List<CriServiceModel> services,
    List<CriProjetModel> projets,
    DashboardPeriod period,
  ) {
    final siteData = <String, _SiteInfo>{};

    void add(String site, String clientName) {
      if (site.isEmpty) return;
      siteData
          .putIfAbsent(site, () => _SiteInfo(siteName: site, clientName: clientName))
          .count++;
    }

    for (final s in services.where((s) => period.contains(s.interventionDate))) {
      add(s.site, s.clientName);
    }
    for (final p in projets.where((p) => period.contains(p.interventionDate))) {
      add(p.site, p.clientName);
    }

    final sorted = siteData.entries.toList()
      ..sort((a, b) => b.value.count.compareTo(a.value.count));

    return sorted.take(20).map((entry) {
      return TopSiteData(
        siteId: entry.key,
        siteName: entry.value.siteName,
        clientName: entry.value.clientName,
        visitCount: entry.value.count,
      );
    }).toList();
  }

  /// Calcule la charge de travail par technicien
  List<TechnicianWorkloadData> calculateTechnicianWorkload(
    List<CriServiceModel> services,
    List<CriProjetModel> projets,
    DashboardPeriod period,
  ) {
    final techData = <String, _TechWorkInfo>{};

    void add(String name, int duration, bool isCompleted) {
      final info = techData.putIfAbsent(name, () => _TechWorkInfo(name: name));
      info.count++;
      if (duration > 0) info.totalMinutes += duration;
      if (isCompleted) info.completedCount++;
    }

    for (final s in services.where((s) => period.contains(s.interventionDate))) {
      add(s.technicianName, s.interventionDurationMinutes, isServiceRealized(s));
    }
    for (final p in projets.where((p) => period.contains(p.interventionDate))) {
      add(p.technicianName, p.durationMinutes, isProjetRealized(p));
    }

    return techData.entries.map((entry) {
      final info = entry.value;
      return TechnicianWorkloadData(
        technicianId: entry.key.toLowerCase().replaceAll(' ', '_'),
        technicianName: entry.key,
        interventionCount: info.count,
        totalHours: info.totalMinutes / 60,
        completionRate: info.count > 0 ? (info.completedCount / info.count) * 100 : 0,
      );
    }).toList()
      ..sort((a, b) => b.interventionCount.compareTo(a.interventionCount));
  }

  /// Nombre moyen d'interventions par technicien sur la période.
  double calculateTeamAverage(
    List<CriServiceModel> services,
    List<CriProjetModel> projets,
    DashboardPeriod period,
  ) {
    final technicianCounts = <String, int>{};
    for (final s in services.where((s) => period.contains(s.interventionDate))) {
      technicianCounts.update(s.technicianName, (c) => c + 1, ifAbsent: () => 1);
    }
    for (final p in projets.where((p) => period.contains(p.interventionDate))) {
      technicianCounts.update(p.technicianName, (c) => c + 1, ifAbsent: () => 1);
    }

    if (technicianCounts.isEmpty) return 0;
    final total = technicianCounts.values.fold<int>(0, (a, b) => a + b);
    return total / technicianCounts.length;
  }

  /// Calcule le taux de résolution au premier passage
  double calculateFirstTimeFixRate(
    List<CriServiceModel> services,
    String? technicianName,
    DashboardPeriod period,
  ) {
    final scoped = services.where((s) =>
        period.contains(s.interventionDate) &&
        (technicianName == null || s.technicianName == technicianName));
    final total = scoped.length;
    if (total == 0) return 0;
    final firstTimeFix = scoped
        .where((s) => isServiceRealized(s) && !s.additionalInterventionRequired)
        .length;
    return (firstTimeFix / total) * 100;
  }

  /// Normalise les données du radar (0-100)
  List<SkillRadarData> normalizeRadarData(
    Map<String, int> categoryData, {
    int maxCategories = 8,
  }) {
    if (categoryData.isEmpty) return [];

    final maxValue = categoryData.values
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final sorted = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(maxCategories).map((entry) {
      return SkillRadarData(
        category: entry.key,
        count: entry.value,
        normalizedValue: maxValue > 0 ? (entry.value / maxValue) * 100 : 0,
      );
    }).toList();
  }

  /// Charge hebdomadaire d'un technicien sur les 8 dernières semaines
  /// (lundi 00:00 → lundi suivant), services et projets.
  List<WorkloadData> calculateWorkloadCurve(
    List<CriServiceModel> services,
    List<CriProjetModel> projets,
    String technicianName,
  ) {
    final now = DateTime.now();
    final currentMonday = DateTime(now.year, now.month, now.day - (now.weekday - 1));

    final items = [
      for (final s in services.where((s) => s.technicianName == technicianName))
        (date: s.interventionDate, minutes: s.interventionDurationMinutes),
      for (final p in projets.where((p) => p.technicianName == technicianName))
        (date: p.interventionDate, minutes: p.durationMinutes),
    ];

    return List.generate(8, (index) {
      final i = 7 - index;
      final weekStart = DateTime(
        currentMonday.year,
        currentMonday.month,
        currentMonday.day - i * 7,
      );
      final weekEnd = DateTime(weekStart.year, weekStart.month, weekStart.day + 7);
      final inWeek = items
          .where((e) => !e.date.isBefore(weekStart) && e.date.isBefore(weekEnd))
          .toList();
      final totalMinutes = inWeek
          .map((e) => e.minutes > 0 ? e.minutes : 0)
          .fold<int>(0, (a, b) => a + b);

      return WorkloadData(
        weekStart: weekStart,
        totalHours: totalMinutes / 60,
        interventionCount: inWeek.length,
        weekLabel: '${weekStart.day}/${weekStart.month}',
      );
    });
  }
}

/// Classe helper pour les infos de site
class _SiteInfo {
  final String siteName;
  final String clientName;
  int count = 0;

  _SiteInfo({required this.siteName, required this.clientName});
}

/// Classe helper pour les infos de technicien
class _TechWorkInfo {
  final String name;
  int count = 0;
  int completedCount = 0;
  double totalMinutes = 0;

  _TechWorkInfo({required this.name});
}

/// Direction de la tendance
enum TrendDirection { up, down, neutral }
