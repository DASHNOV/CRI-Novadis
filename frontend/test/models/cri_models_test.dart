import 'package:flutter_test/flutter_test.dart';
import 'package:novadis_cri/data/models/cri_projet_model.dart';
import 'package:novadis_cri/data/models/cri_service_model.dart';
import 'package:novadis_cri/data/local/tables/cri_projet_table.dart';
import 'package:novadis_cri/data/local/tables/cri_service_table.dart';

void main() {
  group('CriProjetModel', () {
    test('creates empty model with default values', () {
      final model = CriProjetModel.empty(
        id: 'test-id',
        technicianName: 'John Doe',
      );

      expect(model.id, equals('test-id'));
      expect(model.technicianName, equals('John Doe'));
      expect(model.projectPhase, equals(ProjectPhase.etude));
      expect(
        model.interventionType,
        equals(ProjetInterventionType.installationMateriel),
      );
      expect(model.projectStatus, equals(ProjectStatus.enCours));
      expect(model.isDraft, isTrue);
      expect(model.syncStatus, equals('pending'));
      // Numéro de projet vide pour un brouillon (génération auto retirée, cf. commit 4cbd407)
      expect(model.projectNumber, isEmpty);
    });

    test('calculates duration correctly', () {
      final model =
          CriProjetModel.empty(
            id: 'test-id',
            technicianName: 'John Doe',
          ).copyWith(
            startTime: DateTime(2024, 1, 1, 9, 0),
            endTime: DateTime(2024, 1, 1, 11, 30),
          );

      expect(model.durationMinutes, equals(150));
      expect(model.formattedDuration, equals('2h30'));
    });

    test('formats short duration correctly', () {
      final model =
          CriProjetModel.empty(
            id: 'test-id',
            technicianName: 'John Doe',
          ).copyWith(
            startTime: DateTime(2024, 1, 1, 9, 0),
            endTime: DateTime(2024, 1, 1, 9, 45),
          );

      expect(model.durationMinutes, equals(45));
      expect(model.formattedDuration, equals('45min'));
    });

    test('serializes to JSON and back', () {
      final original =
          CriProjetModel.empty(
            id: 'test-id',
            technicianName: 'John Doe',
          ).copyWith(
            clientName: 'Client Test',
            site: 'Site Test',
            projectName: 'Project Test',
            photos: ['photo1.jpg', 'photo2.jpg'],
          );

      final json = original.toJson();
      final restored = CriProjetModel.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.clientName, equals(original.clientName));
      expect(restored.site, equals(original.site));
      expect(restored.projectName, equals(original.projectName));
      expect(restored.photos, equals(original.photos));
    });

    test('copyWith creates new instance with updated values', () {
      final original = CriProjetModel.empty(
        id: 'test-id',
        technicianName: 'John Doe',
      );

      final updated = original.copyWith(
        clientName: 'New Client',
        projectStatus: ProjectStatus.termine,
      );

      expect(updated.clientName, equals('New Client'));
      expect(updated.projectStatus, equals(ProjectStatus.termine));
      expect(updated.id, equals(original.id));
      expect(updated.technicianName, equals(original.technicianName));
    });

    test('equality is based on id', () {
      final model1 = CriProjetModel.empty(
        id: 'same-id',
        technicianName: 'John',
      );
      final model2 = CriProjetModel.empty(
        id: 'same-id',
        technicianName: 'Jane',
      );
      final model3 = CriProjetModel.empty(
        id: 'different-id',
        technicianName: 'John',
      );

      expect(model1, equals(model2));
      expect(model1, isNot(equals(model3)));
    });
  });

  group('SoftwareEntry', () {
    test('displayName uses enum label for known software', () {
      const entry = SoftwareEntry(software: ProjetSoftware.milestone);
      expect(entry.displayName, equals('Milestone'));
    });

    test('displayName uses customName when software is autre', () {
      const entry = SoftwareEntry(
        software: ProjetSoftware.autre,
        customName: 'Genetec',
      );
      expect(entry.displayName, equals('Genetec'));
    });

    test('displayName falls back to "Autre" label when customName is empty', () {
      const entry = SoftwareEntry(
        software: ProjetSoftware.autre,
        customName: '   ',
      );
      expect(entry.displayName, equals('Autre'));
    });

    test('serializes customName to JSON and back', () {
      const original = SoftwareEntry(
        software: ProjetSoftware.autre,
        version: '2.1',
        customName: 'Genetec',
      );

      final restored = SoftwareEntry.fromJson(original.toJson());

      expect(restored.software, equals(ProjetSoftware.autre));
      expect(restored.version, equals('2.1'));
      expect(restored.customName, equals('Genetec'));
    });
  });

  group('CriServiceModel', () {
    test('creates empty model with default values', () {
      final model = CriServiceModel.empty(
        id: 'test-id',
        technicianName: 'John Doe',
      );

      expect(model.id, equals('test-id'));
      expect(model.technicianName, equals('John Doe'));
      expect(model.requestType, equals(ServiceRequestType.depannage));
      expect(model.resolutionStatus, equals(ResolutionStatus.nonResolu));
      expect(model.isDraft, isTrue);
      // Numéro de ticket vide pour un brouillon (génération auto retirée, cf. commit 4cbd407)
      expect(model.ticketNumber, isEmpty);
    });

    test('calculates duration from start and end time', () {
      final duration = CriServiceModel.calculateDuration(
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 1, 9, 0),
        DateTime(2024, 1, 1, 11, 30),
      );

      expect(duration, equals(150));
    });

    test('formats duration correctly', () {
      final model = CriServiceModel.empty(
        id: 'test-id',
        technicianName: 'John Doe',
      ).copyWith(interventionDurationMinutes: 90);

      expect(model.formattedDuration, equals('1h30'));
    });

    test('serializes to JSON and back', () {
      final original =
          CriServiceModel.empty(
            id: 'test-id',
            technicianName: 'John Doe',
          ).copyWith(
            clientName: 'Client Test',
            additionalInterventionRequired: true,
          );

      final json = original.toJson();
      final restored = CriServiceModel.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.clientName, equals(original.clientName));
      expect(
        restored.additionalInterventionRequired,
        equals(original.additionalInterventionRequired),
      );
    });
  });

  group('ProjectPhase enum', () {
    test('has correct labels', () {
      expect(ProjectPhase.etude.label, equals('Étude'));
      expect(ProjectPhase.installation.label, equals('Installation'));
      expect(ProjectPhase.configuration.label, equals('Configuration'));
      expect(ProjectPhase.tests.label, equals('Tests'));
      expect(ProjectPhase.miseEnProduction.label, equals('Mise en production'));
      expect(ProjectPhase.cloture.label, equals('Clôture'));
    });

    test('fromString returns correct value', () {
      expect(ProjectPhase.fromString('etude'), equals(ProjectPhase.etude));
      expect(ProjectPhase.fromString('Étude'), equals(ProjectPhase.etude));
      expect(ProjectPhase.fromString('unknown'), equals(ProjectPhase.etude));
    });
  });

  group('ResolutionStatus enum', () {
    test('has correct labels', () {
      expect(ResolutionStatus.resolu.label, equals('Résolu'));
      expect(
        ResolutionStatus.partiellementResolu.label,
        equals('Partiellement résolu'),
      );
      expect(ResolutionStatus.nonResolu.label, equals('Non résolu'));
      expect(
        ResolutionStatus.enAttentePieces.label,
        equals('En attente pièces'),
      );
      expect(
        ResolutionStatus.escaladeNiveau2.label,
        equals('Escaladé niveau 2'),
      );
    });
  });
}
