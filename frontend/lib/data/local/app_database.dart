import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import conditionnel
import 'connection_stub.dart'
    if (dart.library.io) 'connection_native.dart'
    if (dart.library.js_interop) 'connection_web.dart'
    if (dart.library.html) 'connection_web.dart';

import 'tables/cri_service_table.dart';
import 'tables/cri_projet_table.dart';
import 'tables/exported_document_table.dart';

part 'app_database.g.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

@DriftDatabase(tables: [CriServiceTable, CriProjetTable, ExportedDocumentTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.addColumn(criServiceTable, criServiceTable.cybersecurityRecommendations);
        }
        if (from < 3) {
          await m.addColumn(criProjetTable, criProjetTable.ville);
          await m.addColumn(criProjetTable, criProjetTable.codePostal);
          await m.addColumn(criProjetTable, criProjetTable.pays);
          await m.addColumn(criServiceTable, criServiceTable.ville);
          await m.addColumn(criServiceTable, criServiceTable.codePostal);
          await m.addColumn(criServiceTable, criServiceTable.pays);
        }
        if (from < 4) {
          await m.addColumn(criProjetTable, criProjetTable.softwares);
        }
        if (from < 5) {
          await m.addColumn(criServiceTable, criServiceTable.contratType);
          await m.addColumn(criServiceTable, criServiceTable.systemTypes);
        }
        if (from < 6) {
          await m.addColumn(criServiceTable, criServiceTable.devisARealiser);
          await m.addColumn(criServiceTable, criServiceTable.facturable);
        }
        if (from < 7) {
          await m.addColumn(criServiceTable, criServiceTable.endDate);
          await m.addColumn(criProjetTable, criProjetTable.endDate);
        }
        if (from < 8) {
          await customStatement('ALTER TABLE cri_service DROP COLUMN priority');
        }
      },
      beforeOpen: (details) async {
        // Auto-repair: ensure all expected columns exist in the tables.
        // This handles cases where a prior migration failed halfway through
        // or the database was created with an older schema.
        await _ensureColumnsExist(customStatement);
      },
    );
  }

  /// Checks for missing columns and adds them via raw SQL.
  /// This is a safety net for failed migrations.
  Future<void> _ensureColumnsExist(Future<void> Function(String) exec) async {
    // CRI Service table columns that may be missing
    final serviceColumns = <String, String>{
      'cybersecurity_recommendations': 'TEXT',
      'ville': 'TEXT',
      'code_postal': 'TEXT',
      'pays': 'TEXT',
      'contrat_type': 'TEXT',
      'system_types': 'TEXT',
      'devis_a_realiser': 'INTEGER NOT NULL DEFAULT 0',
      'facturable': 'INTEGER NOT NULL DEFAULT 0',
      'end_date': 'INTEGER',
    };

    // CRI Projet table columns that may be missing
    final projetColumns = <String, String>{
      'ville': 'TEXT',
      'code_postal': 'TEXT',
      'pays': 'TEXT',
      'softwares': 'TEXT',
      'end_date': 'INTEGER',
    };

    for (final entry in serviceColumns.entries) {
      await _addColumnIfMissing('cri_service', entry.key, entry.value, exec);
    }
    for (final entry in projetColumns.entries) {
      await _addColumnIfMissing('cri_projet', entry.key, entry.value, exec);
    }
  }

  Future<void> _addColumnIfMissing(
    String table,
    String column,
    String type,
    Future<void> Function(String) exec,
  ) async {
    try {
      // Try selecting the column – if it doesn't exist, this will throw.
      await customSelect('SELECT "$column" FROM "$table" LIMIT 1').get();
    } catch (_) {
      // Column does not exist – add it.
      try {
        await exec('ALTER TABLE "$table" ADD COLUMN "$column" $type');
      } catch (_) {
        // Column may already exist in some edge cases – ignore.
      }
    }
  }

  // CRI Service Methods
  Future<List<CriService>> getAllCriService() => select(criServiceTable).get();
  Stream<List<CriService>> watchAllCriService() => select(criServiceTable).watch();
  Future<CriService?> getCriServiceById(String id) => (select(criServiceTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<int> insertCriService(CriServiceTableCompanion cri) => into(criServiceTable).insert(cri);
  Future<bool> updateCriService(CriServiceTableCompanion cri) async {
    await into(criServiceTable).insertOnConflictUpdate(cri);
    return true;
  }

  // CRI Projet Methods
  Future<List<CriProjet>> getAllCriProjet() => select(criProjetTable).get();
  Stream<List<CriProjet>> watchAllCriProjet() => select(criProjetTable).watch();
  Future<CriProjet?> getCriProjetById(String id) => (select(criProjetTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<int> insertCriProjet(CriProjetTableCompanion cri) => into(criProjetTable).insert(cri);
  Future<bool> updateCriProjet(CriProjetTableCompanion cri) async {
    await into(criProjetTable).insertOnConflictUpdate(cri);
    return true;
  }
  Future<int> deleteCriProjet(String id) => (delete(criProjetTable)..where((t) => t.id.equals(id))).go();
  Future<int> deleteCriService(String id) => (delete(criServiceTable)..where((t) => t.id.equals(id))).go();

  // Exported Document Methods
  Future<List<ExportedDocument>> getAllExportedDocuments() => select(exportedDocumentTable).get();
  Future<List<ExportedDocument>> getExportedDocumentsByType(String type) => (select(exportedDocumentTable)..where((t) => t.fileType.equals(type))).get();
  Future<List<ExportedDocument>> getExportedDocumentsByCriId(String id) => (select(exportedDocumentTable)..where((t) => t.criId.equals(id))).get();
  Future<ExportedDocument?> getExportedDocumentById(int id) => (select(exportedDocumentTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<int> insertExportedDocument(ExportedDocumentTableCompanion doc) => into(exportedDocumentTable).insert(doc);
  Future<bool> updateExportedDocument(ExportedDocumentTableCompanion doc) => update(exportedDocumentTable).replace(doc);
  Future<int> deleteExportedDocument(int id) => (delete(exportedDocumentTable)..where((t) => t.id.equals(id))).go();
  Future<int> updateSharedAt(int id, DateTime date) => (update(exportedDocumentTable)..where((t) => t.id.equals(id))).write(
      ExportedDocumentTableCompanion(sharedAt: Value(date)),
    );
}

extension CriProjetUtils on CriProjet {
  int get interventionDurationMinutes => endTime.difference(startTime).inMinutes;
}
