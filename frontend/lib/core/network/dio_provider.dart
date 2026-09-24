import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:novadis_cri/core/config/api_config.dart';
import 'package:novadis_cri/core/config/app_router.dart';
import 'package:novadis_cri/core/network/isolate_transformer.dart';
import 'package:novadis_cri/core/storage/storage_service.dart';

const _authEndpointsSkippingRefresh = <String>[
  '/auth/login',
  '/auth/refresh',
  '/auth/verify',
  '/auth/verify-device',
];

bool _isAuthEndpoint(String path) {
  return _authEndpointsSkippingRefresh.any(path.contains);
}

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(storageServiceProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
    ),
  );

  if (!kIsWeb) {
    dio.transformer = BackgroundTransformer()
      ..jsonDecodeCallback = jsonDecodeAndCompute;
  }

  Completer<String?>? refreshCompleter;

  Future<String?> performRefresh() async {
    if (refreshCompleter != null) {
      return refreshCompleter!.future;
    }
    final completer = Completer<String?>();
    refreshCompleter = completer;

    try {
      final refreshToken = await storage.getRefreshToken();
      if (refreshToken == null) {
        completer.complete(null);
        return null;
      }

      final refreshDio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'ngrok-skip-browser-warning': 'true',
          },
        ),
      );
      if (!kIsWeb) {
        refreshDio.transformer = BackgroundTransformer()
          ..jsonDecodeCallback = jsonDecodeAndCompute;
      }

      final response = await refreshDio.post(
        '/auth/refresh',
        data: {
          'refreshToken': refreshToken,
          'deviceInfo': 'Mobile App (Auto-Refresh)',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final newAccessToken = data['accessToken'] as String?;
        final newRefreshToken = data['refreshToken'] as String?;
        if (newAccessToken != null && newRefreshToken != null) {
          await storage.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );
          completer.complete(newAccessToken);
          return newAccessToken;
        }
      }
      completer.complete(null);
      return null;
    } catch (_) {
      completer.complete(null);
      return null;
    } finally {
      refreshCompleter = null;
    }
  }

  Future<void> redirectToLogin() async {
    await storage.clearTokens();
    final context = AppRouter.navigatorKey.currentContext;
    if (context != null && context.mounted) {
      GoRouter.of(context).go(AppRouter.login);
    }
  }

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        // 403 inclus : le jeton est valide, c'est le droit qui manque — ni
        // rafraîchissement ni déconnexion (message : ApiException.fromDio).
        if (e.response?.statusCode != 401) {
          return handler.next(e);
        }

        if (_isAuthEndpoint(e.requestOptions.path)) {
          return handler.next(e);
        }

        final newAccessToken = await performRefresh();
        if (newAccessToken == null) {
          await redirectToLogin();
          return handler.next(e);
        }

        try {
          final options = e.requestOptions;
          options.headers['Authorization'] = 'Bearer $newAccessToken';
          final clonedRequest = await dio.fetch(options);
          return handler.resolve(clonedRequest);
        } catch (_) {
          return handler.next(e);
        }
      },
    ),
  );

  return dio;
});
