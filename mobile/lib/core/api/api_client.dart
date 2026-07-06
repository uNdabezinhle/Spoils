import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

final apiClientProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final access = await tokenStorage.getAccessToken();
        final isPublicAuth = options.path.contains('/auth/login') ||
            options.path.contains('/auth/register') ||
            options.path.contains('/auth/google') ||
            options.path.contains('/auth/apple') ||
            options.path.contains('/auth/refresh') ||
            options.path.contains('/auth/password-reset');
        if (access != null && !isPublicAuth) {
          options.headers['Authorization'] = 'Bearer $access';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refresh = await tokenStorage.getRefreshToken();
          final path = error.requestOptions.path;
          if (refresh != null && !path.contains('/auth/refresh')) {
            try {
              final refreshDio = Dio(dio.options);
              final response = await refreshDio.post(
                '/auth/refresh/',
                data: {'refresh': refresh},
              );
              final newAccess = response.data['access'] as String;
              final newRefresh = response.data['refresh'] as String? ?? refresh;
              await tokenStorage.saveTokens(access: newAccess, refresh: newRefresh);

              error.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
              final retry = await dio.fetch(error.requestOptions);
              return handler.resolve(retry);
            } catch (_) {
              await tokenStorage.clear();
            }
          }
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});