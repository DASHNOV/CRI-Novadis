import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Enregistre le fichier dans `Documents/Novadis/Exports` (comme les exports XLSX).
Future<String> deliverCsv(Uint8List bytes, String filename) async {
  final base = await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(base.path, 'Novadis', 'Exports'));
  if (!await dir.exists()) await dir.create(recursive: true);
  final file = File(p.join(dir.path, filename));
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
