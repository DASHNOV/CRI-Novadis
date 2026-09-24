import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:novadis_cri/data/local/app_database.dart';
import 'package:novadis_cri/data/models/cri_service_model.dart';
import 'package:novadis_cri/features/export/services/pdf_builder_common.dart';
import 'package:pdf/widgets.dart' as pw;

/// Étape 4.5 du plan de remédiation : génération PDF hors de l'isolate
/// d'interface, photos redimensionnées, détection explicite des images en ligne.

/// Constructeur de test : actifs lus sur disque (pas de rootBundle hors app),
/// photos lues sur disque — la même configuration que l'isolate de production.
class _DiskPdfBuilder with PdfBuilderCommon {
  @override
  Future<Uint8List> loadAssetBytes(String key) => File(key).readAsBytes();

  @override
  Future<pw.MemoryImage?> resolveFilePhoto(String filePath) async {
    final file = File(filePath);
    return await file.exists() ? pw.MemoryImage(await file.readAsBytes()) : null;
  }
}

/// Photo synthétique au grain proche d'une vraie (dégradé + bruit) : un
/// aplat se compresse si bien qu'aucun ré-encodage ne l'allègerait.
Uint8List _jpeg(int width, int height) {
  final random = Random(42);
  final image = img.Image(width: width, height: height);
  for (final pixel in image) {
    final noise = random.nextInt(60);
    pixel
      ..r = (pixel.x * 255 ~/ width + noise) % 256
      ..g = (pixel.y * 255 ~/ height + noise) % 256
      ..b = (noise * 3) % 256;
  }
  return Uint8List.fromList(img.encodeJpg(image, quality: 90));
}

CriServiceModel _cri(List<String> photos) {
  final now = DateTime(2026, 9, 24, 8);
  return CriServiceModel.fromDb(CriService(
    id: 'pdf-test',
    interventionDate: now,
    startTime: now,
    endTime: now.add(const Duration(hours: 2)),
    clientName: 'Client PDF',
    site: 'Site Alpha',
    requestType: 'depannage',
    requestDescription: 'Demande **urgente**',
    actionsPerformed: '- Diagnostic\n- Remplacement',
    interventionDurationMinutes: 120,
    resolutionStatus: 'resolu',
    additionalInterventionRequired: false,
    devisARealiser: false,
    facturable: true,
    photos: jsonEncode(photos),
    technicianName: jsonEncode(['Tech Test']),
    createdAt: now,
    syncStatus: 'synced',
    isDraft: false,
  ));
}

void main() {
  group('decodeInlineImage', () {
    final jpeg = _jpeg(16, 16);
    final raw = base64Encode(jpeg);

    test('data URI', () {
      expect(decodeInlineImage('data:image/jpeg;base64,$raw'), jpeg);
    });

    test('base64 brut d\'un ancien CRI, même commençant par « /9j/ »', () {
      expect(raw.startsWith('/9j/'), isTrue);
      expect(decodeInlineImage(raw), jpeg);
    });

    test('un chemin de fichier n\'est jamais pris pour du base64', () {
      for (final path in [
        '/data/user/0/fr.novadis.cri/cache/image_picker_1234567890abcdef.jpg',
        '/storage/emulated/0/DCIM/Camera/IMG_20260924_101500_123456789012.jpg',
        r'C:\Users\tech\Pictures\photo-chantier-alpha-2026-09-24-numero-42.jpg',
        'photo.jpg',
      ]) {
        expect(decodeInlineImage(path), isNull, reason: path);
      }
    });
  });

  group('downscaleForPdf', () {
    test('ramène une grande photo à 1240 px de large', () {
      final resized = img.decodeImage(downscaleForPdf(_jpeg(3000, 2000)))!;
      expect(resized.width, pdfPhotoMaxWidth);
      expect(resized.height, closeTo(2000 * pdfPhotoMaxWidth / 3000, 1));
    });

    test('laisse intacte une photo déjà petite', () {
      final small = _jpeg(800, 600);
      expect(downscaleForPdf(small), same(small));
    });

    test('rend les octets tels quels si l\'image est illisible', () {
      final junk = Uint8List.fromList([1, 2, 3]);
      expect(downscaleForPdf(junk), same(junk));
    });
  });

  test(
      'CRI à dix grandes photos : généré en arrière-plan, la boucle principale '
      'reste libre, et le PDF est allégé', () async {
    final dir = await Directory.systemTemp.createTemp('pdf_isolate_test');
    addTearDown(() => dir.delete(recursive: true));
    final photo = _jpeg(3000, 2000);
    final photos = <String>[];
    for (var i = 0; i < 10; i++) {
      final file = File('${dir.path}/photo_$i.jpg')..writeAsBytesSync(photo);
      photos.add(file.path);
    }
    final cri = _cri(photos);

    // Chronomètre de la boucle principale : chaque tick en retard trahit un
    // blocage, c'est-à-dire un écran figé dans l'app.
    var ticks = 0;
    var worstGapMs = 0;
    var last = DateTime.now();
    final timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final now = DateTime.now();
      final gap = now.difference(last).inMilliseconds;
      if (gap > worstGapMs) worstGapMs = gap;
      last = now;
      ticks++;
    });

    final stopwatch = Stopwatch()..start();
    final bytes = await Isolate.run(
        () async => (await _DiskPdfBuilder().buildCriServiceDocument(cri)).save());
    stopwatch.stop();
    timer.cancel();

    // ignore: avoid_print
    print('Originaux ${photo.length * 10 ~/ 1024} Ko → PDF ${bytes.length ~/ 1024} Ko '
        'en ${stopwatch.elapsedMilliseconds} ms, '
        '$ticks ticks, pire intervalle $worstGapMs ms');

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(worstGapMs, lessThan(250),
        reason: 'la boucle principale ne doit jamais être bloquée');
    // Photos redimensionnées : le PDF pèse au plus la moitié des originaux cumulés
    // (sans redimensionnement, il les contenait tels quels).
    expect(bytes.length, lessThan(photo.length * 10 ~/ 2));
  }, timeout: const Timeout(Duration(minutes: 3)));
}
