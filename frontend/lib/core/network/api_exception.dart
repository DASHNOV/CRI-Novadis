import 'package:dio/dio.dart';

/// Erreur d'appel API porteuse de son code HTTP.
///
/// Les dépôts renvoyaient une simple `String` : le message survivait, le code
/// disparaissait — impossible de distinguer « le réseau n'est pas là, ça
/// repartira tout seul » de « le serveur a refusé ce CRI, il ne passera
/// jamais ». C'est cette distinction que [isPermanent] rend disponible à la
/// synchronisation et à l'interface.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  /// Vrai quand rejouer la même requête à l'identique redonnera la même
  /// réponse : le serveur a compris la demande et l'a refusée.
  ///
  /// Exclus volontairement des codes 4xx :
  /// - `401` : l'intercepteur Dio rafraîchit le jeton et rejoue la requête ;
  ///   un 401 qui remonte jusqu'ici est un problème de session, pas de contenu.
  /// - `408` / `429` : temporisation et limitation de débit, réessayables.
  bool get isPermanent {
    final code = statusCode;
    if (code == null) return false;
    if (code == 401 || code == 408 || code == 429) return false;
    return code >= 400 && code < 500;
  }

  /// Message brut, sans préfixe de type : les écrans existants interpolent
  /// l'exception directement (`'Erreur: $e'`).
  @override
  String toString() => message;

  /// Construit l'exception depuis une [DioException], en préférant le message
  /// métier renvoyé par l'API (`{ "message": "..." }`) à un libellé générique.
  factory ApiException.fromDio(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    if (data is Map) {
      // 1. Réponse métier de l'API : { "message": "..." }
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return ApiException(message, statusCode: status);
      }

      // 2. ValidationProblemDetails d'ASP.NET — la forme que prend un 400 de
      //    validation de modèle : { "title": "...", "errors": { "Champ": [...] } }.
      //    Sans ce cas, le motif se réduisait à « HTTP 400 » et le champ fautif
      //    restait introuvable : exactement l'information qui manque au terrain.
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final details = errors.entries.map((entry) {
          final value = entry.value;
          final text = value is List ? value.join(' ') : '$value';
          return '${entry.key} : $text';
        }).join('\n');
        return ApiException(details, statusCode: status);
      }

      // 3. ProblemDetails sans détail par champ.
      final title = data['title'];
      if (title is String && title.trim().isNotEmpty) {
        return ApiException(title, statusCode: status);
      }
    }
    if (status != null) {
      return ApiException(
        'Le serveur a refusé la requête (HTTP $status)',
        statusCode: status,
      );
    }
    return const ApiException('Erreur de communication avec le serveur');
  }
}
