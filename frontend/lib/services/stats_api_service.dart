import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novadis_cri/core/network/dio_provider.dart';
import 'package:novadis_cri/models/personal_stats.dart';
import 'package:novadis_cri/models/global_stats.dart';
import 'package:novadis_cri/models/technician_activity.dart';
import 'package:novadis_cri/models/daily_activity.dart';
import 'package:novadis_cri/models/monthly_activity.dart';
import 'package:novadis_cri/models/site_stats.dart';
import 'package:novadis_cri/models/technician_detailed_stats.dart';
import 'package:novadis_cri/models/distribution_stats.dart';
import 'package:novadis_cri/models/dashboard_alerts.dart';
import 'package:novadis_cri/models/dashboard_evolution.dart';
import 'package:novadis_cri/models/recent_intervention.dart';
import 'package:novadis_cri/features/dashboard/models/stats_query.dart';

/// Provider pour le StatsApiService
final statsApiServiceProvider = Provider<StatsApiService>((ref) {
  return StatsApiService(ref.watch(dioProvider));
});

/// Service API pour les statistiques personnelles et globales
class StatsApiService {
  final Dio _dio;

  StatsApiService(this._dio);

  // ──────────────────────────────────────────────────
  // 👤 Endpoints personnels (Technician + Admin)
  // ──────────────────────────────────────────────────

  /// Récupère les statistiques personnelles du technicien connecté
  Future<PersonalStats> getPersonalStats() async {
    try {
      final response = await _dio.get('/personal/stats');
      final data = response.data['data'];
      return PersonalStats.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Récupère les CRI personnels avec filtre
  /// [filter] peut être: 'all', 'pending', 'signed', 'in_progress'
  Future<List<Map<String, dynamic>>> getPersonalCRIs({
    String filter = 'all',
  }) async {
    try {
      final response = await _dio.get(
        '/personal/cris',
        queryParameters: {'filter': filter},
      );
      final data = response.data['data'] as List;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Récupère l'activité journalière personnelle pour heatmap
  /// [year] : année spécifique (Jan→Déc), ou null pour les 365 derniers jours
  Future<List<DailyActivity>> getPersonalDailyStats({int? year}) async {
    try {
      final params = year != null ? {'year': year} : <String, dynamic>{};
      final response = await _dio.get('/personal/daily-stats', queryParameters: params);
      final data = response.data['data'] as List;
      return data
          .map((item) => DailyActivity.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Récupère l'activité mensuelle personnelle (6 derniers mois) pour sparkline
  Future<List<MonthlyActivity>> getPersonalMonthlyStats() async {
    try {
      final response = await _dio.get('/personal/monthly-stats');
      final data = response.data['data'] as List;
      return data
          .map((item) => MonthlyActivity.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Récupère les 5 derniers CRI du technicien
  Future<List<Map<String, dynamic>>> getRecentPersonalCRIs() async {
    try {
      final response = await _dio.get('/personal/recent');
      final data = response.data['data'] as List;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ──────────────────────────────────────────────────
  // 🌐 Endpoints globaux (Admin uniquement)
  // ──────────────────────────────────────────────────

  // ──────────────────────────────────────────────────
  // 📊 Dashboard — mêmes calculs, deux périmètres :
  //    global = /api/global (capacité GlobalStats),
  //    sinon  = /api/personal/dashboard (CRI de l'utilisateur connecté).
  // ──────────────────────────────────────────────────

  Future<dynamic> _getData(String path, Map<String, dynamic> queryParameters) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data['data'];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> _getDashboard(
    String globalPath,
    String personalPath,
    StatsQuery query, {
    required bool global,
    Map<String, dynamic> extra = const {},
  }) =>
      _getData(
        global ? globalPath : personalPath,
        {...query.toQueryParameters(), ...extra},
      );

  /// KPI (total, résolus, durée moyenne, récurrences…) du périmètre.
  Future<GlobalStats> getDashboardStats(StatsQuery query, {required bool global}) async {
    final data = await _getDashboard(
      '/global/stats',
      '/personal/dashboard/stats',
      query,
      global: global,
    );
    return GlobalStats.fromJson(data as Map<String, dynamic>);
  }

  /// Statistiques par site.
  Future<List<SiteStats>> getStatsBySite(StatsQuery query, {required bool global}) async {
    final data = await _getDashboard(
      '/global/stats/by-site',
      '/personal/dashboard/by-site',
      query,
      global: global,
    );
    return (data as List)
        .map((item) => SiteStats.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Courbe d'évolution (granularité choisie par l'API).
  Future<DashboardEvolution> getEvolution(StatsQuery query, {required bool global}) async {
    final data = await _getDashboard(
      '/global/stats/evolution',
      '/personal/dashboard/evolution',
      query,
      global: global,
    );
    return DashboardEvolution.fromJson(data as Map<String, dynamic>);
  }

  /// Dernières interventions (date d'intervention décroissante).
  Future<List<RecentIntervention>> getRecentInterventions(
    StatsQuery query, {
    required bool global,
    int limit = 10,
  }) async {
    final data = await _getDashboard(
      '/global/stats/recent',
      '/personal/dashboard/recent',
      query,
      global: global,
      extra: {'limit': limit},
    );
    return (data as List)
        .map((item) => RecentIntervention.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Alertes : sites à forte récurrence, services non résolus depuis
  /// [staleDays] jours, escalades.
  Future<DashboardAlerts> getAlerts(
    StatsQuery query, {
    required bool global,
    int staleDays = 14,
  }) async {
    final data = await _getDashboard(
      '/global/stats/alerts',
      '/personal/dashboard/alerts',
      query,
      global: global,
      extra: {'staleDays': staleDays},
    );
    return DashboardAlerts.fromJson(data as Map<String, dynamic>);
  }

  /// Statistiques par technicien (global uniquement).
  Future<List<TechnicianDetailedStats>> getStatsByTechnician(StatsQuery query) async {
    final data =
        await _getData('/global/stats/by-technician', query.toQueryParameters());
    return (data as List)
        .map((item) => TechnicianDetailedStats.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Statistiques croisées (global uniquement).
  Future<DistributionStats> getDistributionStats(StatsQuery query) async {
    final data =
        await _getData('/global/stats/distribution', query.toQueryParameters());
    return DistributionStats.fromJson(data as Map<String, dynamic>);
  }

  /// Récupère tous les CRI avec info technicien (admin uniquement)
  Future<List<Map<String, dynamic>>> getAllCRIsWithTechnician({
    String? technicienId,
    String filter = 'all',
    String? searchId,
  }) async {
    try {
      final queryParams = <String, dynamic>{'filter': filter};
      if (technicienId != null) {
        queryParams['technicienId'] = technicienId;
      }
      if (searchId != null && searchId.isNotEmpty) {
        queryParams['searchId'] = searchId;
      }

      final response = await _dio.get(
        '/global/cris',
        queryParameters: queryParams,
      );
      final data = response.data['data'] as List;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Récupère l'activité de tous les techniciens (admin uniquement)
  Future<List<TechnicianActivity>> getTechnicianActivity() async {
    try {
      final response = await _dio.get('/global/activity');
      final data = response.data['data'] as List;
      return data
          .map(
            (item) => TechnicianActivity.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Données pour graphique d'activité des 7 derniers jours (admin uniquement)
  Future<List<DailyActivity>> getActivityChartData() async {
    try {
      final response = await _dio.get('/global/activity-chart');
      final data = response.data['data'] as List;
      return data
          .map((item) => DailyActivity.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Marqueur écrit dans `clientSignature` lorsqu'un CRI est validé manuellement
  /// (sans capture de signature physique). Doit rester synchronisé avec
  /// `UpdateSignatureDto.ManualValidationMarker` côté backend.
  static const String manualValidationMarker = 'MANUAL_VALIDATION';

  /// Met à jour manuellement le statut "Signé / En attente" d'un CRI.
  /// Passe `setSigned: true` pour marquer signé, `false` pour repasser en attente.
  /// Le backend rejette toute tentative de modification sur un CRI dont l'appelant
  /// n'est pas le propriétaire (strict, même pour les admins).
  Future<void> toggleClientSignature(String criId, {required bool setSigned}) async {
    try {
      await _dio.patch(
        '/cri/$criId/signature',
        data: {
          'clientSignature': setSigned ? manualValidationMarker : null,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Récupère la liste des techniciens pour le filtre dropdown (admin)
  Future<List<Map<String, dynamic>>> getTechnicians() async {
    try {
      final response = await _dio.get('/global/technicians');
      final data = response.data['data'] as List;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ──────────────────────────────────────────────────
  // 🔧 Gestion des erreurs
  // ──────────────────────────────────────────────────

  String _handleError(DioException e) {
    final status = e.response?.statusCode;
    if (status == 403) {
      return 'Accès refusé. Ce CRI ne vous appartient pas.';
    }
    if (status == 401) {
      return 'Session expirée. Veuillez vous reconnecter.';
    }
    if (status == 404) {
      return 'Endpoint introuvable (404). Le backend est-il à jour ?';
    }
    if (status == 405) {
      return 'Méthode non autorisée (405). Le backend est-il à jour ?';
    }
    if (e.response != null && e.response?.data != null) {
      final data = e.response?.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'];
      }
    }
    if (status != null) {
      return 'Erreur HTTP $status. Veuillez réessayer.';
    }
    return 'Erreur réseau (${e.type.name}). Veuillez réessayer.';
  }
}
