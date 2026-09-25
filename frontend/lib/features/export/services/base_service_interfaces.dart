import 'dart:typed_data';

import '../models/exported_document_model.dart';

/// Résultat d'un export PDF sur le web (bytes + filename pour upload serveur).
class PdfWebResult {
  final Uint8List bytes;
  final String filename;
  const PdfWebResult({required this.bytes, required this.filename});
}

abstract class BasePdfGeneratorService {
  Future<dynamic> generateCriServicePDF(String criId);
  Future<dynamic> generateCriProjetPDF(String criId);
}

abstract class BaseFileManagementService {
  Future<bool> openFile(String filePath);
  Future<bool> shareFile(String filePath, {String? subject, String? text});
  Future<bool> shareMultipleFiles(List<String> filePaths, {String? subject, String? text});
  Future<bool> deleteFile(int documentId);
  Future<int> deleteMultipleFiles(List<int> documentIds);
  Future<bool> renameFile(int documentId, String newFilename);
  Future<void> markAsShared(int documentId);
  Future<int> registerExportedDocument({
    required dynamic file,
    required DocumentFileType fileType,
    required ExportType exportType,
    String? criId,
    Map<String, dynamic>? metadata,
  });
}
