import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ApiClient(tokenStorage);
});

class ApiClient {
  late final Dio _dio;
  final TokenStorage _tokenStorage;

  ApiClient(this._tokenStorage) {
    print('🔵 Initializing API Client with base URL: ${AppConfig.apiBaseUrl}');
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: Duration(milliseconds: AppConfig.apiConnectTimeout),
        receiveTimeout: Duration(milliseconds: AppConfig.apiReceiveTimeout),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Token expired or invalid - try to refresh
            final refreshed = await _refreshToken();
            if (refreshed) {
              // Retry the request with new token
              final token = await _tokenStorage.getAccessToken();
              error.requestOptions.headers['Authorization'] = 'Bearer $token';
              final response = await _dio.fetch(error.requestOptions);
              return handler.resolve(response);
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await _tokenStorage.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Dio get dio => _dio;
}
