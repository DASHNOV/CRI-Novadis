import 'dart:io' show File;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;

import '../../../core/network/dio_provider.dart';
import '../../../data/local/app_database.dart';
import '../models/exported_document_model.dart';
import '../models/server_exported_document.dart';
import '../services/base_service_interfaces.dart' show BasePdfGeneratorService, BaseFileManagementService, PdfWebResult;
import '../services/service_factory.dart' as service_factory;
import '../services/xlsx_export_api_service.dart';
import '../services/exported_documents_api_service.dart';

export '../services/xlsx_export_api_service.dart' show XlsxExportPeriod, XlsxExportPeriodX, XlsxExportResult, XlsxDetailLevel, XlsxDetailLevelX;
export '../models/server_exported_document.dart';

// ============================================================
// Providers de services
// ============================================

/// Provider pour la base de données — délègue au singleton appDatabaseProvider
final databaseProvider = Provider<AppDatabase>((ref) {
  return ref.watch(appDatabaseProvider);
});

/// Provider pour le service PDF
final pdfGeneratorServiceProvider = Provider<BasePdfGeneratorService>((ref) {
  final database = ref.watch(databaseProvider);
  return service_factory.getPdfService(database);
});

/// Provider pour le service de gestion de fichiers
final fileManagementServiceProvider = Provider<BaseFileManagementService>((ref) {
  final database = ref.watch(databaseProvider);
  return service_factory.getFileService(database);
});

/// Provider pour le service XLSX (backend via Dio)
final xlsxExportApiServiceProvider = Provider<XlsxExportApiService>((ref) {
  return XlsxExportApiService(ref.watch(dioProvider));
});

/// Provider pour le service d'historique serveur (liste / download / delete / rename / upload).
final exportedDocumentsApiServiceProvider = Provider<ExportedDocumentsApiService>((ref) {
  return ExportedDocumentsApiService(ref.watch(dioProvider));
});

/// Filtres côté serveur (fileType / exportType).
class ServerDocumentsFilter {
  final String? fileType;
  final String? exportType;
  const ServerDocumentsFilter({this.fileType, this.exportType});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServerDocumentsFilter &&
          fileType == other.fileType &&
          exportType == other.exportType;

  @override
  int get hashCode => fileType.hashCode ^ exportType.hashCode;
}

/// Liste des documents côté serveur (Admin -> tous, Technicien -> les siens).
final serverDocumentsProvider =
    FutureProvider.family<List<ServerExportedDocument>, ServerDocumentsFilter>((ref, filter) async {
  final api = ref.watch(exportedDocumentsApiServiceProvider);
  return api.list(fileType: filter.fileType, exportType: filter.exportType);
});

/// Filtre actif pour la liste serveur.
final serverDocumentsFilterProvider =
    StateProvider<ServerDocumentsFilter>((ref) => const ServerDocumentsFilter());

/// Recherche texte + tri côté client sur la liste serveur.
final serverSearchQueryProvider = StateProvider<String>((ref) => '');
final serverSortProvider = StateProvider<DocumentSortOption>((ref) => DocumentSortOption.newestFirst);

/// Documents sélectionnés (pour actions multiples, par id UUID).
final selectedServerDocumentsProvider = StateProvider<Set<String>>((ref) => {});

// ============================================================
// Providers de données
// ============================================================

/// Provider pour tous les documents exportés
/// Filtre automatiquement les enregistrements dont le fichier n'existe plus sur le disque
final exportedDocumentsProvider = FutureProvider<List<ExportedDocument>>((
  ref,
) async {
  if (kIsWeb) return [];
  final database = ref.watch(databaseProvider);
  final allDocs = await database.getAllExportedDocuments();

  // Vérifier que chaque fichier existe encore sur le disque
  final validDocs = <ExportedDocument>[];
  for (final doc in allDocs) {
    if (await File(doc.filePath).exists()) {
      validDocs.add(doc);
    } else {
      // Supprimer les enregistrements orphelins de la DB
      debugPrint('[Documents] Fichier manquant, suppression DB: ${doc.filePath}');
      await database.deleteExportedDocument(doc.id);
    }
  }

  return validDocs;
});

/// Provider pour les documents filtrés
final filteredDocumentsProvider =
    FutureProvider.family<List<ExportedDocument>, DocumentFilter>((
      ref,
      filter,
    ) async {
      if (kIsWeb) return [];
      // Utiliser le provider principal comme source de vérité pour que l'invalidation fonctionne
      final documentsSource = await ref.watch(exportedDocumentsProvider.future);
      // Créer une nouvelle liste pour éviter de modifier la source
      var documents = List<ExportedDocument>.from(documentsSource);

      // Appliquer les filtres
      if (filter.fileType != null) {
        documents = documents
            .where((doc) => doc.fileType == filter.fileType!.name)
            .toList();
      }

      if (filter.exportType != null) {
        documents = documents
            .where((doc) => doc.exportType == filter.exportType!.name)
            .toList();
      }

      if (filter.startDate != null && filter.endDate != null) {
        documents = documents.where((doc) {
          return doc.createdAt.isAfter(filter.startDate!) &&
              doc.createdAt.isBefore(
                filter.endDate!.add(const Duration(days: 1)),
              );
        }).toList();
      }

      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        final query = filter.searchQuery!.toLowerCase();
        documents = documents.where((doc) {
          return doc.filename.toLowerCase().contains(query) ||
              (doc.metadata?.toLowerCase().contains(query) ?? false);
        }).toList();
      }

      return documents;
    });

/// Provider pour les documents PDF uniquement
final pdfDocumentsProvider = FutureProvider<List<ExportedDocument>>((
  ref,
) async {
  if (kIsWeb) return [];
  final database = ref.watch(databaseProvider);
  return await database.getExportedDocumentsByType('pdf');
});

/// Provider pour les documents CSV uniquement
final csvDocumentsProvider = FutureProvider<List<ExportedDocument>>((
  ref,
) async {
  if (kIsWeb) return [];
  final database = ref.watch(databaseProvider);
  return await database.getExportedDocumentsByType('csv');
});

/// Provider pour les documents d'un CRI spécifique
final criDocumentsProvider =
    FutureProvider.family<List<ExportedDocument>, String>((ref, criId) async {
      if (kIsWeb) return [];
      final database = ref.watch(databaseProvider);
      return await database.getExportedDocumentsByCriId(criId);
    });

// ============================================================
// Providers d'état
// ============================================================

/// État du filtre actuel
final documentFilterProvider = StateProvider<DocumentFilter>(
  (ref) => const DocumentFilter(),
);

/// Option de tri actuelle
final documentSortProvider = StateProvider<DocumentSortOption>(
  (ref) => DocumentSortOption.newestFirst,
);

/// Documents sélectionnés (pour actions multiples)
final selectedDocumentsProvider = StateProvider<Set<int>>((ref) => {});

/// État de l'export en cours
final exportProgressProvider = StateProvider<ExportProgress?>((ref) => null);

/// Recherche active - Synchronisé avec le filtre
final searchQueryProvider = StateProvider<String>((ref) => '');

// ============================================================
// Providers d'actions
// ============================================================

/// Provider pour générer un PDF CRI
final generateCriPdfProvider = FutureProvider.family<dynamic, String>((
  ref,
  criId,
) async {
  final service = ref.watch(pdfGeneratorServiceProvider);
  final database = ref.watch(databaseProvider);

  // Mettre à jour le progrès
  Future.microtask(() {
    ref.read(exportProgressProvider.notifier).state = ExportProgress(
      type: 'PDF',
      status: 'Recherche du rapport...',
      progress: 0.1,
    );
  });

  try {
    dynamic file;

    // 1. Chercher dans CRI Service
    final serviceCri = await database.getCriServiceById(criId);
    if (serviceCri != null) {
      Future.microtask(() {
        ref.read(exportProgressProvider.notifier).state = ExportProgress(
          type: 'PDF',
          status: 'Génération CRI Service...',
          progress: 0.5,
        );
      });
      file = await service.generateCriServicePDF(criId);
    }

    // 2. Si non trouvé, chercher dans CRI Projet
    if (file == null) {
      final projetCri = await database.getCriProjetById(criId);
      if (projetCri != null) {
        Future.microtask(() {
          ref.read(exportProgressProvider.notifier).state = ExportProgress(
            type: 'PDF',
            status: 'Génération CRI Projet...',
            progress: 0.5,
          );
        });
        file = await service.generateCriProjetPDF(criId);
      }
    }

    if (file == null) {
      throw Exception('Rapport non trouvé (ID: $criId)');
    }

    if (kIsWeb) {
      // Sur web : le PDF a été téléchargé par le navigateur, on l'uploade aussi sur le serveur
      try {
        final result = file as PdfWebResult;
        final api = ref.read(exportedDocumentsApiServiceProvider);
        await api.upload(
          bytes: result.bytes,
          filename: result.filename,
          criId: criId,
          exportType: 'cri',
        );
        ref.invalidate(serverDocumentsProvider);
      } catch (e) {
        debugPrint('[PDF] Upload serveur échoué (non bloquant): $e');
      }
    } else {
      final fileService = ref.watch(fileManagementServiceProvider);
      await fileService.registerExportedDocument(
        file: file,
        fileType: DocumentFileType.pdf,
        exportType: ExportType.cri,
        criId: criId,
      );
      ref.invalidate(exportedDocumentsProvider);

      // Upload côté serveur pour apparaître dans l'inventaire global
      try {
        final fileObj = file as File;
        final bytes = await fileObj.readAsBytes();
        final api = ref.read(exportedDocumentsApiServiceProvider);
        await api.upload(
          bytes: bytes,
          filename: fileObj.uri.pathSegments.last,
          criId: criId,
          exportType: 'cri',
        );
        ref.invalidate(serverDocumentsProvider);
      } catch (e) {
        debugPrint('[PDF] Upload serveur échoué (non bloquant): $e');
      }
    }

    // Réinitialiser le progrès
    ref.read(exportProgressProvider.notifier).state = ExportProgress(
      type: 'PDF',
      status: 'Terminé',
      progress: 1.0,
    );

    return file;
  } catch (e) {
    ref.read(exportProgressProvider.notifier).state = ExportProgress(
      type: 'PDF',
      status: 'Erreur: $e',
      progress: 0.0,
      hasError: true,
    );
    rethrow;
  }
});

/// Provider pour générer un XLSX d'un CRI via le backend.
final exportCriXlsxProvider = FutureProvider.family<XlsxExportResult, String>((
  ref,
  criId,
) async {
  final api = ref.watch(xlsxExportApiServiceProvider);

  Future.microtask(() {
    ref.read(exportProgressProvider.notifier).state = ExportProgress(
      type: 'XLSX',
      status: 'Génération du classeur...',
      progress: 0.3,
    );
  });

  try {
    final result = await api.exportCri(criId);

    if (!kIsWeb && result.file is File) {
      final fileService = ref.watch(fileManagementServiceProvider);
      await fileService.registerExportedDocument(
        file: result.file,
        fileType: DocumentFileType.xlsx,
        exportType: ExportType.cri,
        criId: criId,
      );
      ref.invalidate(exportedDocumentsProvider);
    }

    // Le backend a déjà persisté le XLSX (cf. ExportController), il suffit de rafraîchir.
    ref.invalidate(serverDocumentsProvider);

    ref.read(exportProgressProvider.notifier).state = ExportProgress(
      type: 'XLSX',
      status: 'Terminé',
      progress: 1.0,
    );
    return result;
  } catch (e) {
    ref.read(exportProgressProvider.notifier).state = ExportProgress(
      type: 'XLSX',
      status: 'Erreur: $e',
      progress: 0.0,
      hasError: true,
    );
    rethrow;
  }
});

/// Paramètres pour l'export XLSX par période.
typedef XlsxPeriodParams = ({
  XlsxExportPeriod period,
  DateTime referenceDate,
  XlsxDetailLevel detailLevel,
});

/// Provider pour générer un XLSX agrégé (jour/semaine/mois/année).
final exportPeriodXlsxProvider =
    FutureProvider.family<XlsxExportResult, XlsxPeriodParams>((ref, params) async {
  final api = ref.watch(xlsxExportApiServiceProvider);

  Future.microtask(() {
    ref.read(exportProgressProvider.notifier).state = ExportProgress(
      type: 'XLSX',
      status: 'Génération (${params.period.label})...',
      progress: 0.3,
    );
  });

  try {
    final result = await api.exportPeriod(
      period: params.period,
      referenceDate: params.referenceDate,
      detailLevel: params.detailLevel,
    );

    if (!kIsWeb && result.file is File) {
      final fileService = ref.watch(fileManagementServiceProvider);
      await fileService.registerExportedDocument(
        file: result.file,
        fileType: DocumentFileType.xlsx,
        exportType: ExportType.dashboard,
        metadata: {
          'period': params.period.slug,
          'referenceDate': params.referenceDate.toIso8601String(),
          'detailLevel': params.detailLevel.slug,
        },
      );
      ref.invalidate(exportedDocumentsProvider);
    }

    ref.invalidate(serverDocumentsProvider);

    ref.read(exportProgressProvider.notifier).state = ExportProgress(
      type: 'XLSX',
      status: 'Terminé',
      progress: 1.0,
    );
    return result;
  } catch (e) {
    ref.read(exportProgressProvider.notifier).state = ExportProgress(
      type: 'XLSX',
      status: 'Erreur: $e',
      progress: 0.0,
      hasError: true,
    );
    rethrow;
  }
});

/// Provider pour les documents XLSX uniquement
final xlsxDocumentsProvider = FutureProvider<List<ExportedDocument>>((
  ref,
) async {
  if (kIsWeb) return [];
  final database = ref.watch(databaseProvider);
  return await database.getExportedDocumentsByType('xlsx');
});

// ============================================================
// Modèles
// ============================================================

/// Progrès d'un export
class ExportProgress {
  final String type;
  final String status;
  final double progress;
  final bool hasError;

  ExportProgress({
    required this.type,
    required this.status,
    required this.progress,
    this.hasError = false,
  });
}
