import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novadis_cri/core/network/api_exception.dart';
import 'package:novadis_cri/core/network/dio_provider.dart';
import 'package:novadis_cri/data/local/app_database.dart';
import 'package:novadis_cri/data/repositories/cri_remote_repository.dart';
import 'package:novadis_cri/services/sync_service.dart';

/// Étape 4.2 du plan de remédiation : un CRI ne passe « synced » que si le
/// serveur a reçu le CRI **et** ses photos. L'ancien `catch (_) {}` autour de
/// l'envoi des photos le marquait synchronisé quand elles échouaient : elles
/// n'étaient alors jamais renvoyées.

CriService _pendingRow(String id, {List<String> photos = const []}) {
  final now = DateTime(2026, 9, 24, 8);
  return CriService(
    id: id,
    interventionDate: now,
    startTime: now,
    endTime: now.add(const Duration(hours: 1)),
    clientName: 'Client $id',
    site: 'Site',
    requestType: 'depannage',
    requestDescription: 'demande',
    actionsPerformed: 'actions',
    interventionDurationMinutes: 60,
    resolutionStatus: 'resolu',
    additionalInterventionRequired: false,
    devisARealiser: false,
    facturable: false,
    photos: jsonEncode(photos),
    technicianName: jsonEncode(['Tech']),
    createdAt: now,
    syncStatus: 'pending',
    isDraft: false,
  );
}

class _FakeDb implements AppDatabase {
  _FakeDb(this.rows);

  final List<CriService> rows;

  /// syncStatus écrit par id, lors des mises à jour.
  final Map<String, String> writtenStatus = {};

  @override
  Future<List<CriService>> getAllCriService() async =>
      rows.where((r) => writtenStatus[r.id] != 'synced').toList();

  @override
  Future<List<CriProjet>> getAllCriProjet() async => const [];

  @override
  Future<bool> updateCriService(CriServiceTableCompanion cri) async {
    writtenStatus[cri.id.value] = cri.syncStatus.value;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRemote implements CriRemoteRepository {
  Object? saveError;
  Object? uploadError;
  final List<String> saved = [];
  final Map<String, List<String>> uploaded = {};

  @override
  Future<void> saveCriService(dynamic cri) async {
    if (saveError != null) throw saveError!;
    saved.add(cri.id as String);
  }

  @override
  Future<void> uploadPhotos(String criId, List<String> localPaths) async {
    if (uploadError != null) throw uploadError!;
    uploaded[criId] = localPaths;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeDb db;
  late _FakeRemote remote;
  late ProviderContainer container;
  late SyncService sync;

  void setUpWith(List<CriService> rows) {
    db = _FakeDb(rows);
    remote = _FakeRemote();
    container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      criRemoteRepositoryProvider.overrideWithValue(remote),
      dioProvider.overrideWithValue(Dio()),
    ]);
    sync = container.read(syncServiceProvider);
  }

  tearDown(() => container.dispose());

  test('succès : CRI et photos envoyés, puis marqué synced', () async {
    setUpWith([_pendingRow('a', photos: ['/p/1.jpg', '/p/2.jpg'])]);

    expect(await sync.syncPendingCris(), 1);
    expect(remote.uploaded['a'], ['/p/1.jpg', '/p/2.jpg']);
    expect(db.writtenStatus['a'], 'synced');
    expect(container.read(pendingCriCountProvider), 0);
  });

  test("échec d'envoi des photos : le CRI reste pending et sera rejoué",
      () async {
    setUpWith([_pendingRow('a', photos: ['/p/1.jpg'])]);
    remote.uploadError = const ApiException('Délai dépassé');

    expect(await sync.syncPendingCris(), 0);
    expect(db.writtenStatus.containsKey('a'), isFalse,
        reason: 'le CRI ne doit pas passer synced sans ses photos');
    expect(container.read(pendingCriCountProvider), 1);

    // Réseau revenu : la passe suivante renvoie les photos et conclut.
    remote.uploadError = null;
    expect(await sync.retryNow(), 1);
    expect(remote.uploaded['a'], ['/p/1.jpg']);
    expect(db.writtenStatus['a'], 'synced');
  });

  test('panne réseau : pending, et aucun motif de refus affiché', () async {
    setUpWith([_pendingRow('a')]);
    remote.saveError = const ApiException('Erreur de communication avec le serveur');

    expect(await sync.syncPendingCris(), 0);
    expect(db.writtenStatus.containsKey('a'), isFalse);
    expect(container.read(syncFailuresProvider), isEmpty);
  });

  test('refus serveur 400 : pending, motif affiché sur la carte', () async {
    setUpWith([_pendingRow('a')]);
    remote.saveError =
        const ApiException('Statut de CRI invalide', statusCode: 400);

    await sync.syncPendingCris();
    expect(db.writtenStatus.containsKey('a'), isFalse);
    expect(container.read(syncFailuresProvider)['a'], 'Statut de CRI invalide');
  });

  test('photo refusée (400) : motif affiché, CRI non marqué synced', () async {
    setUpWith([_pendingRow('a', photos: ['/p/enorme.jpg'])]);
    remote.uploadError = const ApiException(
        'Photo refusée : enorme.jpg (12 Mo, maximum 10 Mo)',
        statusCode: 400);

    await sync.syncPendingCris();
    expect(db.writtenStatus.containsKey('a'), isFalse);
    expect(container.read(syncFailuresProvider)['a'], contains('enorme.jpg'));
  });

  test("un CRI en échec n'empêche pas les autres de partir", () async {
    setUpWith([
      _pendingRow('a', photos: ['/p/1.jpg']),
      _pendingRow('b'),
    ]);
    remote.uploadError = const ApiException('Délai dépassé');

    expect(await sync.syncPendingCris(), 1);
    expect(db.writtenStatus['b'], 'synced');
    expect(db.writtenStatus.containsKey('a'), isFalse);
  });
}
