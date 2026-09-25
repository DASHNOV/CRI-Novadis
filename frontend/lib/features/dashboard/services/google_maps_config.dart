import 'package:flutter/foundation.dart';

import 'google_maps_loader_stub.dart'
    if (dart.library.js_interop) 'google_maps_loader_web.dart' as loader;

/// Configuration Google Maps de la carte des sites.
///
/// La clé n'est **jamais** dans le dépôt : elle est injectée au build par
/// `--dart-define=GOOGLE_MAPS_API_KEY=…` (Vercel : variable d'environnement lue
/// par `build_vercel.sh` ; Android : Gradle la reprend dans le manifeste).
/// Sans clé, le dashboard garde la carte Plan IGN.
class GoogleMapsConfig {
  static const apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  static bool get isConfigured => apiKey.isNotEmpty;

  /// Charge le SDK JavaScript (web) une seule fois ; immédiat sur mobile.
  static Future<void> ensureLoaded() => loader.ensureGoogleMapsLoaded(apiKey);

  /// `true` si Google a refusé la clé (web) : repli sur le Plan IGN.
  static ValueListenable<bool> get authFailed => loader.googleMapsAuthFailed;
}
