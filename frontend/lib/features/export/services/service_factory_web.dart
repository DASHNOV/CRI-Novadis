import '../../../data/local/app_database.dart';
import '../models/exported_document_model.dart';
import 'base_service_interfaces.dart';
import 'pdf_generator_web.dart';

class WebFileManagementService implements BaseFileManagementService {
  WebFileManagementService(AppDatabase db);
  @override
  Future<bool> openFile(String filePath) async => false;
  @override
  Future<bool> shareFile(String filePath, {String? subject, String? text}) async => false;
  @override
  Future<bool> shareMultipleFiles(List<String> filePaths, {String? subject, String? text}) async => false;
  @override
  Future<bool> deleteFile(int documentId) async => false;
  @override
  Future<int> deleteMultipleFiles(List<int> documentIds) async => 0;
  @override
  Future<bool> renameFile(int documentId, String newFilename) async => false;
  @override
  Future<void> markAsShared(int documentId) async {}
  @override
  Future<int> registerExportedDocument({required dynamic file, required DocumentFileType fileType, required ExportType exportType, String? criId, Map<String, dynamic>? metadata}) async => 0;
}

BasePdfGeneratorService createPdfService(AppDatabase db) => PdfGeneratorService(db);
BaseFileManagementService createFileManagementService(AppDatabase db) => WebFileManagementService(db);
