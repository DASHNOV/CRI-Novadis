import 'package:novadis_cri/models/recent_intervention.dart';

/// Alertes du dashboard (`/stats/alerts`) : ce qui demande une action.
class DashboardAlerts {
  final double seuilRecurrence;
  final int minInterventionsSite;
  final int joursSansResolution;
  final List<SiteAlert> sitesRecurrence;
  final int criNonResolusTotal;
  final List<RecentIntervention> criNonResolus;
  final int escaladesTotal;
  final List<RecentIntervention> escalades;

  const DashboardAlerts({
    required this.seuilRecurrence,
    required this.minInterventionsSite,
    required this.joursSansResolution,
    required this.sitesRecurrence,
    required this.criNonResolusTotal,
    required this.criNonResolus,
    required this.escaladesTotal,
    required this.escalades,
  });

  factory DashboardAlerts.fromJson(Map<String, dynamic> json) {
    List<RecentIntervention> interventions(Object? list) => (list as List? ?? const [])
        .map((e) => RecentIntervention.fromJson(e as Map<String, dynamic>))
        .toList();
    return DashboardAlerts(
      seuilRecurrence: (json['seuilRecurrence'] as num?)?.toDouble() ?? 20,
      minInterventionsSite: json['minInterventionsSite'] as int? ?? 0,
      joursSansResolution: json['joursSansResolution'] as int? ?? 14,
      sitesRecurrence: (json['sitesRecurrence'] as List? ?? const [])
          .map((e) => SiteAlert.fromJson(e as Map<String, dynamic>))
          .toList(),
      criNonResolusTotal: json['criNonResolusTotal'] as int? ?? 0,
      criNonResolus: interventions(json['criNonResolus']),
      escaladesTotal: json['escaladesTotal'] as int? ?? 0,
      escalades: interventions(json['escalades']),
    );
  }

  bool get isEmpty =>
      sitesRecurrence.isEmpty && criNonResolusTotal == 0 && escaladesTotal == 0;
}

class SiteAlert {
  final String siteNom;
  final String? clientNom;
  final int totalInterventions;
  final int totalRecurrenceRequise;
  final double tauxRecurrence;

  const SiteAlert({
    required this.siteNom,
    this.clientNom,
    required this.totalInterventions,
    required this.totalRecurrenceRequise,
    required this.tauxRecurrence,
  });

  factory SiteAlert.fromJson(Map<String, dynamic> json) {
    return SiteAlert(
      siteNom: json['siteNom'] as String? ?? '',
      clientNom: json['clientNom'] as String?,
      totalInterventions: json['totalInterventions'] as int? ?? 0,
      totalRecurrenceRequise: json['totalRecurrenceRequise'] as int? ?? 0,
      tauxRecurrence: (json['tauxRecurrence'] as num?)?.toDouble() ?? 0,
    );
  }
}
