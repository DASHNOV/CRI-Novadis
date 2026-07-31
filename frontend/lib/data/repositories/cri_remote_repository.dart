import 'dart:convert';
import 'dart:io' show File;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novadis_cri/core/network/dio_provider.dart';
import 'package:novadis_cri/data/models/cri_photo_model.dart';
import 'package:novadis_cri/data/models/cri_projet_model.dart';
import 'package:novadis_cri/data/models/cri_service_model.dart';
import 'package:novadis_cri/data/models/site_model.dart';
import 'package:novadis_cri/data/local/tables/cri_projet_table.dart';
import 'package:novadis_cri/data/local/tables/cri_service_table.dart';

final criRemoteRepositoryProvider = Provider<CriRemoteRepository>((ref) {
  return CriRemoteRepository(ref.read(dioProvider));
});

class CriRemoteRepository {
  final Dio _dio;

  CriRemoteRepository(this._dio);

  Future<List<dynamic>> getAllCris() async {
    try {
      final response = await _dio.get('/CRI');
      final dynamic responseData = response.data['data'];
      
      if (responseData == null || responseData is! List) {
        return [];
      }

      final List<dynamic> rawData = responseData;
      final List<dynamic> result = [];
      
      for (var item in rawData) {
        try {
          final String? type = item['interventionType'];
          final String? jsonData = item['data'];

          if (jsonData != null && jsonData.isNotEmpty) {
            try {
              final Map<String, dynamic> modelData = jsonDecode(jsonData);
              if (type == 'Project') {
                result.add(CriProjetModel.fromJson(modelData));
              } else {
                result.add(CriServiceModel.fromJson(modelData));
              }
              continue; // Successfully decoded from JSON
            } catch (e) {
              // If JSON decode fails, fallback to creating from flat properties
            }
          }

          // FALLBACK: Create minimal model from flat properties if JSON is missing/corrupt
          final id = item['id']?.toString() ?? '';
          final date = DateTime.tryParse(item['interventionDate']?.toString() ?? '') ?? DateTime.now();
          final clientName = item['clientName']?.toString() ?? 'Client Inconnu';
          final techName = '${item['technicianFirstName'] ?? ''} ${item['technicianLastName'] ?? ''}'.trim();
          final technicianName = techName.isNotEmpty ? techName : (item['technicianEmail']?.toString() ?? 'Technicien');

          if (type == 'Project') {
            result.add(CriProjetModel(
              id: id,
              interventionDate: date,
              startTime: date,
              endTime: date.add(const Duration(hours: 2)),
              clientName: clientName,
              site: item['clientSite']?.toString() ?? '',
              address: item['clientAddress']?.toString(),
              projectName: 'Projet sans titre',
              projectNumber: 'PRJ-SQL',
              projectPhase: ProjectPhase.etude,
              interventionType: ProjetInterventionType.installationMateriel,
              workDescription: item['workDescription']?.toString() ?? '',
              projectStatus: ProjectStatus.enCours,
              technicianNames: [technicianName],
              createdAt: date,
            ));
          } else {
            result.add(CriServiceModel(
              id: id,
              interventionDate: date,
              startTime: date,
              endTime: date.add(const Duration(hours: 1)),
              ticketNumber: 'TICK-SQL',
              clientName: clientName,
              site: item['clientSite']?.toString() ?? '',
              address: item['clientAddress']?.toString(),
              requestType: ServiceRequestType.depannage,
              requestDescription: item['workDescription']?.toString() ?? '',
              actionsPerformed: item['workDescription']?.toString() ?? '',
              interventionDurationMinutes: (item['duration'] != null)
                  ? ((item['duration'] as num).toDouble()).toInt()
                  : 60,
              resolutionStatus: ResolutionStatus.resolu,
              technicianNames: [technicianName],
              createdAt: date,
            ));
          }
        } catch (e) {
          // Skip individual corrupt items
          continue;
        }
      }
      return result;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Récupère un CRI depuis le serveur et le décode depuis la colonne JSON
  /// `data`. Renvoie un [CriServiceModel] ou [CriProjetModel] selon le type,
  /// ou `null` si introuvable / non décodable.
  Future<dynamic> fetchCriById(String id) async {
    try {
      final response = await _dio.get('/CRI/$id');
      final item = response.data['data'];
      if (item == null) return null;

      final String? type = item['interventionType']?.toString();
      final String? jsonData = item['data']?.toString();
      if (jsonData == null || jsonData.isEmpty) return null;

      final Map<String, dynamic> modelData = jsonDecode(jsonData);
      if (type == 'Project') {
        return CriProjetModel.fromJson(modelData);
      }
      return CriServiceModel.fromJson(modelData);
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCriProjet(CriProjetModel cri) async {
    try {
      final data = {
        'id': cri.id,
        'interventionType': 'Project',
        'category': cri.interventionType.label,
        'interventionDate': cri.interventionDate.toIso8601String(),
        'clientName': cri.clientName,
        'clientAddress': cri.address,
        'clientSite': cri.site,
        'clientPhone': cri.phone,
        'clientEmail': cri.email,
        'workDescription': cri.workDescription,
        'materialsUsed': cri.materialsUsed,
        'duration': cri.durationMinutes / 60.0,
        'status': cri.isDraft ? 'Draft' : 'Submitted',
        'technicianSignature': cri.technicianSignature,
        'clientSignature': cri.clientSignature,
        'data': jsonEncode(
          cri.toJson(),
        ), // Save full JSON in Data column for now
      };

      await _dio.post('/CRI', data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> saveCriService(CriServiceModel cri) async {
    try {
      final data = {
        'id': cri.id,
        'interventionType': 'Service',
        'category': cri.requestType.label,
        'interventionDate': cri.interventionDate.toIso8601String(),
        'clientName': cri.clientName,
        'clientAddress': cri.address,
        'clientSite': cri.site,
        'clientPhone': cri.phone,
        'clientEmail': cri.email,
        'workDescription': cri.requestDescription,
        'materialsUsed': cri.replacedParts,
        'duration': cri.interventionDurationMinutes / 60.0,
        'status': cri.isDraft ? 'Draft' : 'Submitted',
        'technicianSignature': cri.technicianSignature,
        'clientSignature': cri.clientSignature,
        'data': jsonEncode(
          cri.toJson(),
        ), // Save full JSON in Data column for now
      };

      await _dio.post('/CRI', data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<String>> getTechnicians() async {
    try {
      final response = await _dio.get('/Users/technicians');
      final List<dynamic> rawData = response.data['data'];

      return rawData
          .map<String>((e) {
            final firstName = e['firstName'] ?? '';
            final lastName = e['lastName'] ?? '';
            return '$firstName $lastName'.trim();
          })
          .where((name) => name.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      debugPrint('Erreur récupération techniciens: ${e.message}');
      return [];
    }
  }

  String _handleError(DioException e) {
    if (e.response != null && e.response?.data != null) {
      final data = e.response?.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'];
      }
    }
    return 'Erreur de communication avec le serveur';
  }

  /// Upload des photos vers le serveur après soumission d'un CRI (mobile uniquement).
  Future<void> uploadPhotos(String criId, List<String> localPaths) async {
    if (kIsWeb) return;

    final formData = FormData();
    for (final path in localPaths) {
      if (path.isEmpty) continue;
      final file = File(path);
      if (!await file.exists()) continue;
      final mime = _getMimeType(path);
      formData.files.add(MapEntry(
        'files',
        await MultipartFile.fromFile(path,
            filename: path.split('/').last,
            contentType: DioMediaType.parse(mime)),
      ));
    }
    if (formData.files.isEmpty) return;

    await _dio.post(
      '/CRI/$criId/photos',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  String _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }

  Future<void> deleteCri(String criId) async {
    try {
      await _dio.delete('/CRI/$criId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Récupère les photos serveur d'un CRI.
  Future<List<CriPhotoModel>> fetchCriPhotos(String criId) async {
    try {
      final response = await _dio.get('/CRI/$criId');
      final data = response.data['data'] as Map<String, dynamic>?;
      if (data == null) return [];
      final List<dynamic> photos = data['photos'] ?? [];
      return photos
          .map((p) => CriPhotoModel.fromJson(p as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Erreur récupération photos CRI: $e');
      return [];
    }
  }

  Future<List<String>> searchClients(String query) async {
    try {
      if (query.isEmpty) return [];
      final response = await _dio.get(
        '/CRI/clients/search',
        queryParameters: {'q': query},
      );
      final List<dynamic> data = response.data['data'] ?? [];
      return data.cast<String>();
    } catch (e) {
      debugPrint('Erreur recherche clients: $e');
      return [];
    }
  }

  Future<List<String>> searchSites(String client, String query) async {
    try {
      if (query.isEmpty) return [];
      final response = await _dio.get(
        '/CRI/sites/search',
        queryParameters: {'client': client, 'q': query},
      );
      final List<dynamic> data = response.data['data'] ?? [];
      return data.cast<String>();
    } catch (e) {
      debugPrint('Erreur recherche sites: $e');
      return [];
    }
  }

  /// Recherche des sites NovaDIS depuis la base de données
  Future<List<SiteModel>> searchSitesFromDatabase(String query) async {
    try {
      if (query.length < 2) return [];
      final response = await _dio.get(
        '/Sites/search',
        queryParameters: {'q': query},
      );
      final List<dynamic> data = response.data['data'] ?? [];
      return data
          .map<SiteModel>((e) => SiteModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Erreur recherche sites DB: $e');
      return [];
    }
  }
}
