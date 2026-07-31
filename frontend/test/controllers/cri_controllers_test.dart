import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novadis_cri/features/cri_form/controllers/cri_projet_controller.dart';
import 'package:novadis_cri/features/cri_form/controllers/cri_service_controller.dart';
import 'package:novadis_cri/data/local/tables/cri_projet_table.dart';
import 'package:novadis_cri/data/local/tables/cri_service_table.dart';
import 'package:novadis_cri/data/local/app_database.dart';
import 'package:novadis_cri/data/repositories/cri_remote_repository.dart';
import 'package:novadis_cri/core/network/dio_provider.dart';

class FakeAppDatabase implements AppDatabase {
  @override
  Future<bool> updateCriProjet(dynamic entity) async => true;
  @override
  Future<bool> updateCriService(dynamic entity) async => true;
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCriRemoteRepository implements CriRemoteRepository {
  @override
  Future<void> saveCriProjet(dynamic cri) async {
    throw Exception('Simulated network error');
  }
  @override
  Future<void> saveCriService(dynamic cri) async {
    throw Exception('Simulated network error');
  }
  @override
  Future<List<String>> getTechnicians() async => [];
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CriProjetFormNotifier', () {
    late ProviderContainer container;
    late CriProjetFormNotifier notifier;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(FakeAppDatabase()),
          criRemoteRepositoryProvider.overrideWithValue(FakeCriRemoteRepository()),
          dioProvider.overrideWithValue(Dio()),
        ],
      );
      notifier = container.read(criProjetFormProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has no current CRI', () {
      final state = container.read(criProjetFormProvider);
      expect(state.currentCri, isNull);
      expect(state.isLoading, isFalse);
      expect(state.isDirty, isFalse);
    });

    test('initNewForm creates a new CRI with default values', () {
      notifier.initNewForm(technicianName: 'Test Technician');

      final state = container.read(criProjetFormProvider);
      expect(state.currentCri, isNotNull);
      expect(state.currentCri!.technicianName, equals('Test Technician'));
      expect(state.currentCri!.projectPhase, equals(ProjectPhase.etude));
      expect(state.isDirty, isFalse);
    });

    test('updateGeneralInfo updates the state and marks as dirty', () {
      notifier.initNewForm(technicianName: 'Test');

      final newDate = DateTime(2024, 6, 15);
      notifier.updateGeneralInfo(interventionDate: newDate);

      final state = container.read(criProjetFormProvider);
      expect(state.currentCri!.interventionDate, equals(newDate));
      expect(state.isDirty, isTrue);
    });

    test('updateClientInfo updates client fields', () {
      notifier.initNewForm(technicianName: 'Test');

      notifier.updateClientInfo(
        clientName: 'Client A',
        site: 'Site A',
        email: 'client@example.com',
      );

      final state = container.read(criProjetFormProvider);
      expect(state.currentCri!.clientName, equals('Client A'));
      expect(state.currentCri!.site, equals('Site A'));
      expect(state.currentCri!.email, equals('client@example.com'));
    });

    test('updateProjectInfo updates project fields', () {
      notifier.initNewForm(technicianName: 'Test');

      notifier.updateProjectInfo(
        projectName: 'New Project',
        projectNumber: 'PRJ-2024-001',
        projectPhase: ProjectPhase.configuration,
      );

      final state = container.read(criProjetFormProvider);
      expect(state.currentCri!.projectName, equals('New Project'));
      expect(state.currentCri!.projectNumber, equals('PRJ-2024-001'));
      expect(
        state.currentCri!.projectPhase,
        equals(ProjectPhase.configuration),
      );
    });

    test('updatePhotos updates photo list', () {
      notifier.initNewForm(technicianName: 'Test');

      notifier.updatePhotos(['photo1.jpg', 'photo2.jpg']);

      final state = container.read(criProjetFormProvider);
      expect(state.currentCri!.photos, equals(['photo1.jpg', 'photo2.jpg']));
    });

    test('updateTechnicianSignature updates signature path', () {
      notifier.initNewForm(technicianName: 'Test');

      notifier.updateTechnicianSignature('/path/to/signature.png');

      final state = container.read(criProjetFormProvider);
      expect(
        state.currentCri!.technicianSignature,
        equals('/path/to/signature.png'),
      );
    });

    test('reset clears all state', () {
      notifier.initNewForm(technicianName: 'Test');
      notifier.updateClientInfo(clientName: 'Client');

      notifier.reset();

      final state = container.read(criProjetFormProvider);
      expect(state.currentCri, isNull);
      expect(state.isDirty, isFalse);
    });

    test('saveDraft sets lastAutoSave and clears isDirty', () async {
      notifier.initNewForm(technicianName: 'Test');
      notifier.updateClientInfo(clientName: 'Client');

      expect(container.read(criProjetFormProvider).isDirty, isTrue);

      await notifier.saveDraft();

      final state = container.read(criProjetFormProvider);
      expect(state.isDirty, isFalse);
      expect(state.lastAutoSave, isNotNull);
      expect(state.currentCri!.isDraft, isTrue);
    });

    test('submit marks CRI as not draft', () async {
      notifier.initNewForm(technicianName: 'Test');

      await notifier.submit();

      final state = container.read(criProjetFormProvider);
      expect(state.currentCri!.isDraft, isFalse);
      expect(state.currentCri!.syncStatus, equals('pending'));
    });
  });

  group('CriServiceFormNotifier', () {
    late ProviderContainer container;
    late CriServiceFormNotifier notifier;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(FakeAppDatabase()),
          criRemoteRepositoryProvider.overrideWithValue(FakeCriRemoteRepository()),
          dioProvider.overrideWithValue(Dio()),
        ],
      );
      notifier = container.read(criServiceFormProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('initNewForm creates a new CRI Service with default values', () {
      notifier.initNewForm(technicianName: 'Test Technician');

      final state = container.read(criServiceFormProvider);
      expect(state.currentCri, isNotNull);
      expect(state.currentCri!.technicianName, equals('Test Technician'));
      expect(
        state.currentCri!.resolutionStatus,
        equals(ResolutionStatus.nonResolu),
      );
    });

    test('updateGeneralInfo auto-calculates duration', () {
      notifier.initNewForm(technicianName: 'Test');

      final startTime = DateTime(2024, 1, 1, 9, 0);
      final endTime = DateTime(2024, 1, 1, 11, 30);

      notifier.updateGeneralInfo(startTime: startTime, endTime: endTime);

      final state = container.read(criServiceFormProvider);
      expect(state.currentCri!.interventionDurationMinutes, equals(150));
    });

    test('updateFollowUpInfo handles conditional fields', () {
      notifier.initNewForm(technicianName: 'Test');

      notifier.updateFollowUpInfo(
        additionalInterventionRequired: true,
        followUpDate: DateTime(2024, 6, 1),
        followUpComments: 'Need to check again',
      );

      final state = container.read(criServiceFormProvider);
      expect(state.currentCri!.additionalInterventionRequired, isTrue);
      expect(state.currentCri!.followUpDate, isNotNull);
      expect(state.currentCri!.followUpComments, equals('Need to check again'));
    });
  });
}
