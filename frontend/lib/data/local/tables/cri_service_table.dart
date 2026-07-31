import 'package:drift/drift.dart';

/// Table Drift pour les CRI Service
/// Contient tous les champs des 8 sections du formulaire
@DataClassName('CriService')
class CriServiceTable extends Table {
  // Clé primaire
  TextColumn get id => text()();

  // Section 1: Général
  DateTimeColumn get interventionDate => dateTime()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get ticketNumber =>
      text().withLength(max: 50).nullable()();

  // Section 2: Client
  TextColumn get clientName => text()();
  TextColumn get site => text()();
  TextColumn get address => text().nullable()();
  TextColumn get ville => text().nullable()();
  TextColumn get codePostal => text().nullable()();
  TextColumn get pays => text().nullable()();
  TextColumn get clientContact => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();

  // Section 3: Demande
  TextColumn get requestType => text()(); // Enum value
  TextColumn get requestDescription => text()();

  // Statut du contrat (facultatif) — Sous contrat / Hors contrat
  TextColumn get contratType => text().nullable()();

  // Types de système concernés (obligatoire à la soumission, JSON array)
  // Valeurs possibles : video, controleAcces, intrusion
  TextColumn get systemTypes => text().nullable()();

  // Section 4: Diagnostic
  TextColumn get diagnosticPerformed => text().nullable()();
  TextColumn get identifiedCause => text().nullable()();

  // Section 5: Intervention
  TextColumn get actionsPerformed => text()();
  TextColumn get replacedParts => text().nullable()();
  IntColumn get interventionDurationMinutes => integer()(); // Durée en minutes

  // Section 6: Résultat
  TextColumn get resolutionStatus => text()(); // Enum value
  TextColumn get testsPerformed => text().nullable()();
  TextColumn get recommendations => text().nullable()();
  TextColumn get cybersecurityRecommendations => text().nullable()();

  // Section 7: Suivi
  BoolColumn get additionalInterventionRequired =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get followUpDate => dateTime().nullable()();
  TextColumn get followUpComments => text().nullable()();
  BoolColumn get devisARealiser =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get facturable =>
      boolean().withDefault(const Constant(false))();

  // Section 8: Validation
  TextColumn get photos => text().nullable()(); // JSON array of paths
  TextColumn get technicianName => text()();
  TextColumn get technicianSignature => text().nullable()(); // Base64 or path
  TextColumn get clientSignature => text().nullable()(); // Base64 or path

  // Métadonnées
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(
    const Constant('pending'),
  )(); // pending, synced, failed
  BoolColumn get isDraft => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'cri_service';
}

/// Types de demande service
enum ServiceRequestType {
  maintenancePreventive('Maintenance préventive'),
  maintenanceCorrective('Maintenance corrective'),
  depannage('Dépannage'),
  supportTechnique('Support technique');

  final String label;
  const ServiceRequestType(this.label);

  static ServiceRequestType fromString(String value) {
    return ServiceRequestType.values.firstWhere(
      (e) => e.name == value || e.label == value,
      orElse: () => ServiceRequestType.depannage,
    );
  }
}

/// Statut du contrat (facultatif)
enum ServiceContratType {
  sousContrat('Sous contrat'),
  horsContrat('Hors contrat');

  final String label;
  const ServiceContratType(this.label);

  static ServiceContratType? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final v in ServiceContratType.values) {
      if (v.name == value || v.label == value) return v;
    }
    return null;
  }
}

/// Type de système concerné par l'intervention (sélection multiple, obligatoire)
enum ServiceSystemType {
  video('Vidéo'),
  controleAcces('Contrôle d\'accès'),
  intrusion('Intrusion'),
  hypervision('Hypervision');

  final String label;
  const ServiceSystemType(this.label);

  static ServiceSystemType? fromString(String? value) {
    if (value == null) return null;
    for (final v in ServiceSystemType.values) {
      if (v.name == value || v.label == value) return v;
    }
    return null;
  }
}

/// Statuts de résolution
enum ResolutionStatus {
  resolu('Résolu'),
  partiellementResolu('Partiellement résolu'),
  nonResolu('Non résolu'),
  enAttentePieces('En attente pièces'),
  escaladeNiveau2('Escaladé niveau 2');

  final String label;
  const ResolutionStatus(this.label);

  static ResolutionStatus fromString(String value) {
    return ResolutionStatus.values.firstWhere(
      (e) => e.name == value || e.label == value,
      orElse: () => ResolutionStatus.nonResolu,
    );
  }
}
