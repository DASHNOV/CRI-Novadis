// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:js_interop';

import 'package:flutter/foundation.dart';

/// Rappel global appelé par le SDK quand Google refuse la clé (référent non
/// autorisé, API non activée, facturation absente…).
@JS('gm_authFailure')
external set _gmAuthFailure(JSFunction callback);

/// Passe à `true` si Google refuse la clé : la carte bascule sur le Plan IGN.
final ValueNotifier<bool> googleMapsAuthFailed = ValueNotifier(false);

Future<void>? _loading;

/// Injecte le SDK Maps JavaScript puis `markerclusterer` (regroupement des
/// marqueurs, version exigée par google_maps_flutter_web 0.6), une seule fois.
/// Chargé à la demande plutôt que dans `index.html` : la clé vient du build et
/// les pages sans carte ne paient pas le chargement.
Future<void> ensureGoogleMapsLoaded(String apiKey) {
  return _loading ??= () async {
    // Avant le chargement : le SDK vérifie la clé dès l'initialisation.
    _gmAuthFailure = (() => googleMapsAuthFailed.value = true).toJS;
    try {
      await _inject(
        'https://maps.googleapis.com/maps/api/js?key=${Uri.encodeQueryComponent(apiKey)}&language=fr&region=FR',
      );
      await _inject(
        'https://cdn.jsdelivr.net/npm/@googlemaps/markerclusterer@2.5.3/dist/index.umd.min.js',
      );
    } catch (_) {
      _loading = null; // réessayable (réseau coupé, etc.)
      rethrow;
    }
  }();
}

Future<void> _inject(String src) async {
  final script = html.ScriptElement()
    ..src = src
    ..async = false;
  html.document.head!.append(script);
  await Future.any([
    script.onLoad.first,
    script.onError.first.then((_) => throw Exception('Chargement impossible : $src')),
  ]);
}
