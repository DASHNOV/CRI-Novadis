import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../data/local/app_database.dart';
import '../../../data/models/cri_projet_model.dart';
import '../../../data/models/cri_service_model.dart';
import 'base_service_interfaces.dart';
import 'pdf_builder_common.dart';

/// Lit une image locale (photo ou signature). Utilisable dans tout isolate.
Future<pw.MemoryImage?> _readImageFile(String filePath) async {
  try {
    final file = File(filePath);
    if (await file.exists()) {
      return pw.MemoryImage(await file.readAsBytes());
    }
  } catch (e) {
    debugPrint('[PDF] Erreur lecture fichier photo: $e');
  }
  return null;
}

/// Construit le document dans un isolate d'arrière-plan. Les actifs (logo,
/// polices) arrivent préchargés : `rootBundle` n'existe que dans l'isolate
/// principal. Les photos, elles, sont lues ici — `dart:io` fonctionne partout.
class _IsolatePdfBuilder with PdfBuilderCommon {
  _IsolatePdfBuilder(this._assets);

  final Map<String, Uint8List> _assets;

  @override
  Future<Uint8List> loadAssetBytes(String key) async =>
      _assets[key] ?? (throw StateError('Actif non préchargé : $key'));

  @override
  Future<pw.MemoryImage?> resolveFilePhoto(String filePath) =>
      _readImageFile(filePath);
}

/// Service de génération de PDF pour les CRI (Version Native)
/// Reproduit le format officiel Novadis avec mise en page professionnelle
///
/// La mise en page et `save()` tournent hors de l'isolate d'interface : sur un
/// CRI à dix photos, ils figeaient l'écran (progression comprise) plusieurs
/// secondes sur un téléphone d'entrée de gamme.
class PdfGeneratorService with PdfBuilderCommon implements BasePdfGeneratorService {
  final AppDatabase _database;

  PdfGeneratorService(this._database);

  Map<String, Uint8List>? _assets;

  /// Logo et polices, lus une seule fois dans l'isolate principal. Un actif
  /// manquant est simplement absent : le document retombe alors sur ses
  /// valeurs de repli (pas de logo, police Helvetica), comme avant.
  Future<Map<String, Uint8List>> _preloadAssets() async {
    if (_assets != null) return _assets!;
    final assets = <String, Uint8List>{};
    for (final key in PdfBuilderCommon.pdfAssetKeys) {
      try {
        assets[key] = await loadAssetBytes(key);
      } catch (e) {
        debugPrint('[PDF] Actif introuvable ($key) : $e');
      }
    }
    return _assets = assets;
  }

  // Méthodes statiques : la fermeture passée à Isolate.run ne doit capturer
  // ni `this` ni la base Drift, qui ne franchissent pas la frontière d'isolate.
  static Future<Uint8List> _buildServiceInBackground(
          CriServiceModel cri, Map<String, Uint8List> assets) =>
      Isolate.run(() async =>
          (await _IsolatePdfBuilder(assets).buildCriServiceDocument(cri)).save());

  static Future<Uint8List> _buildProjetInBackground(
          CriProjetModel cri, Map<String, Uint8List> assets) =>
      Isolate.run(() async =>
          (await _IsolatePdfBuilder(assets).buildCriProjetDocument(cri)).save());

  @override
  Future<pw.MemoryImage?> resolveFilePhoto(String filePath) =>
      _readImageFile(filePath);

  @override
  Future<dynamic> generateCriServicePDF(String criId) async {
    final criData = await _database.getCriServiceById(criId);
    if (criData == null) throw Exception('CRI Service non trouvé: $criId');
    final cri = CriServiceModel.fromDb(criData);

    final bytes = await _buildServiceInBackground(cri, await _preloadAssets());
    return await _savePDF(
      bytes,
      'CRI_Service_${cri.ticketNumber}_${formatDateForFilename(DateTime.now())}',
    );
  }

  @override
  Future<dynamic> generateCriProjetPDF(String criId) async {
    final criData = await _database.getCriProjetById(criId);
    if (criData == null) throw Exception('CRI Projet non trouvé: $criId');
    final cri = CriProjetModel.fromDb(criData);

    final bytes = await _buildProjetInBackground(cri, await _preloadAssets());
    return await _savePDF(
      bytes,
      'CRI_Projet_${cri.projectNumber}_${formatDateForFilename(DateTime.now())}',
    );
  }

  Future<File> _savePDF(Uint8List bytes, String filename) async {
    final output = await getApplicationDocumentsDirectory();
    debugPrint('[PDF] Documents dir: ${output.path}');

    final novadisDir = Directory(p.join(output.path, 'Novadis', 'CRI'));
    if (!await novadisDir.exists()) {
      await novadisDir.create(recursive: true);
      debugPrint('[PDF] Créé dossier: ${novadisDir.path}');
    }

    final filePath = p.join(novadisDir.path, '$filename.pdf');
    final File file = File(filePath);
    debugPrint('[PDF] PDF généré: ${bytes.length} bytes');

    await file.writeAsBytes(bytes, flush: true);
    debugPrint('[PDF] Fichier écrit: $filePath');

    final exists = await file.exists();
    final size = exists ? await file.length() : 0;
    debugPrint('[PDF] Vérification: exists=$exists, size=$size');

    if (!exists) {
      throw Exception('Échec de l\'écriture du fichier PDF: $filePath');
    }

    return file;
  }
}
