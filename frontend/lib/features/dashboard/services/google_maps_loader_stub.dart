import 'package:flutter/foundation.dart';

/// Mobile : un refus de clé n'est pas remonté au code Dart (carte grise, erreur
/// dans les logs Android) ; reste à `false`.
final ValueNotifier<bool> googleMapsAuthFailed = ValueNotifier(false);

/// Mobile : le SDK natif est embarqué, la clé est lue dans le manifeste Android.
Future<void> ensureGoogleMapsLoaded(String apiKey) async {}
