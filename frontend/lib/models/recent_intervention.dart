import 'package:novadis_cri/data/local/tables/cri_projet_table.dart';
import 'package:novadis_cri/data/local/tables/cri_service_table.dart';

/// Intervention récente du dashboard (`/stats/recent`), sans le détail du CRI.
class RecentIntervention {
  final String id;

  /// `Service` ou `Project`.
  final String interventionType;
  final String category;
  final DateTime interventionDate;
  final String technicianId;
  final String technicienNom;
  final String? siteNom;
  final String clientNom;
  final String? resolutionStatus;
  final String? projectStatus;
  final int? dureeMinutes;

  const RecentIntervention({
    required this.id,
    required this.interventionType,
    required this.category,
    required this.interventionDate,
    required this.technicianId,
    required this.technicienNom,
    this.siteNom,
    required this.clientNom,
    this.resolutionStatus,
    this.projectStatus,
    this.dureeMinutes,
  });

  factory RecentIntervention.fromJson(Map<String, dynamic> json) {
    return RecentIntervention(
      id: json['id'] as String,
      interventionType: json['interventionType'] as String? ?? '',
      category: json['category'] as String? ?? '',
      interventionDate: DateTime.parse(json['interventionDate'] as String),
      technicianId: json['technicianId'] as String? ?? '',
      technicienNom: json['technicienNom'] as String? ?? '',
      siteNom: json['siteNom'] as String?,
      clientNom: json['clientNom'] as String? ?? '',
      resolutionStatus: json['resolutionStatus'] as String?,
      projectStatus: json['projectStatus'] as String?,
      dureeMinutes: json['dureeMinutes'] as int?,
    );
  }

  bool get isProject => interventionType == 'Project';

  /// Type attendu par la route `cri-view` (`service` / `projet`).
  String get source => isProject ? 'projet' : 'service';

  String get typeLabel => isProject ? 'Projet' : 'Service';

  /// Libellé du statut (valeurs stockées = noms des enums du formulaire).
  String get statusLabel {
    if (isProject) {
      return ProjectStatus.values
              .where((s) => s.name == projectStatus)
              .firstOrNull
              ?.label ??
          (projectStatus ?? '—');
    }
    return ResolutionStatus.values
            .where((s) => s.name == resolutionStatus)
            .firstOrNull
            ?.label ??
        (resolutionStatus ?? '—');
  }
}
