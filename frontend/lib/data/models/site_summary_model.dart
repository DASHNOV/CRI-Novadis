class SiteSummaryModel {
  final String siteName;
  final String lastVisitStatus;
  final int recurrenceLast6Months;
  final List<SiteTimelineEventModel> timeline;
  final List<String> recommendations;
  final bool chronicityAlert;
  final String? chronicProblemDescription;
  final String? mostFrequentTechnician;
  final String resolutionTrend;
  final double? averageDurationMinutes;

  SiteSummaryModel({
    required this.siteName,
    required this.lastVisitStatus,
    required this.recurrenceLast6Months,
    required this.timeline,
    required this.recommendations,
    required this.chronicityAlert,
    this.chronicProblemDescription,
    this.mostFrequentTechnician,
    this.resolutionTrend = 'Inconnu',
    this.averageDurationMinutes,
  });

  factory SiteSummaryModel.fromJson(Map<String, dynamic> json) {
    return SiteSummaryModel(
      siteName: json['siteName'] as String,
      lastVisitStatus: json['lastVisitStatus'] as String,
      recurrenceLast6Months: json['recurrenceLast6Months'] as int,
      timeline: (json['timeline'] as List<dynamic>)
          .map((e) => SiteTimelineEventModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      recommendations: (json['recommendations'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      chronicityAlert: json['chronicityAlert'] as bool,
      chronicProblemDescription: json['chronicProblemDescription'] as String?,
      mostFrequentTechnician: json['mostFrequentTechnician'] as String?,
      resolutionTrend: (json['resolutionTrend'] as String?) ?? 'Inconnu',
      averageDurationMinutes: (json['averageDurationMinutes'] as num?)?.toDouble(),
    );
  }
}

class SiteTimelineEventModel {
  final DateTime date;
  final String identifiedCause;
  final String replacedParts;
  final String technicianName;
  final String status;

  SiteTimelineEventModel({
    required this.date,
    required this.identifiedCause,
    required this.replacedParts,
    required this.technicianName,
    required this.status,
  });

  factory SiteTimelineEventModel.fromJson(Map<String, dynamic> json) {
    return SiteTimelineEventModel(
      date: DateTime.parse(json['date'] as String),
      identifiedCause: json['identifiedCause'] as String,
      replacedParts: json['replacedParts'] as String,
      technicianName: json['technicianName'] as String,
      status: json['status'] as String,
    );
  }
}
