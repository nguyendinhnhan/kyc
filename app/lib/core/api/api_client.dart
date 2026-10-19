import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(tokenStorageProvider));
});

class ApiClient {
  final TokenStorage _tokenStorage;
  late final Dio _dio;
  late final Dio _refreshDio;
  Future<bool>? _refreshFuture;
  int _sessionVersion = 0;

  ApiClient(this._tokenStorage, {Dio? dio, Dio? refreshDio}) {
    BaseOptions options() => BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: Duration(milliseconds: AppConfig.apiConnectTimeout),
      receiveTimeout: Duration(milliseconds: AppConfig.apiReceiveTimeout),
      headers: {'Content-Type': 'application/json'},
    );
    _dio = dio ?? Dio(options());
    _refreshDio = refreshDio ?? Dio(options());
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) async {
          request.extra.putIfAbsent('sessionVersion', () => _sessionVersion);
          if (request.extra['sessionVersion'] != _sessionVersion) {
            return handler.reject(
              DioException(
                requestOptions: request,
                type: DioExceptionType.cancel,
              ),
            );
          }
          final token = await _tokenStorage.getAccessToken();
          if (request.extra['sessionVersion'] != _sessionVersion) {
            return handler.reject(
              DioException(
                requestOptions: request,
                type: DioExceptionType.cancel,
              ),
            );
          }
          if (token != null && !request.path.startsWith('/auth/')) {
            request.headers['Authorization'] = 'Bearer $token';
          } else if (token != null && request.path == '/auth/logout') {
            request.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(request);
        },
        onError: (error, handler) async {
          final request = error.requestOptions;
          if (error.response?.statusCode != 401 ||
              request.path.startsWith('/auth/') ||
              request.extra['retried'] == true ||
              request.extra['sessionVersion'] != _sessionVersion) {
            return handler.next(error);
          }
          try {
            // A concurrent response may arrive after another request already rotated.
            var token = await _tokenStorage.getAccessToken();
            if (request.headers['Authorization'] == 'Bearer $token') {
              if (!await _refreshToken()) return handler.next(error);
              token = await _tokenStorage.getAccessToken();
            }
            if (token == null ||
                request.extra['sessionVersion'] != _sessionVersion) {
              return handler.next(error);
            }
            request.extra['retried'] = true;
            request.headers['Authorization'] = 'Bearer $token';
            if (request.data is FormData) {
              request.data = (request.data as FormData).clone();
            }
            final response = await _dio.fetch<dynamic>(request);
            handler.resolve(response);
          } on DioException catch (retryError) {
            handler.next(retryError);
          } catch (_) {
            handler.next(error);
          }
        },
      ),
    );
  }

  Future<bool> _refreshToken() async {
    final ongoing = _refreshFuture;
    if (ongoing != null) return ongoing;
    final future = _performRefresh(_sessionVersion);
    _refreshFuture = future;
    try {
      return await future;
    } finally {
      if (identical(_refreshFuture, future)) _refreshFuture = null;
    }
  }

  Future<bool> _performRefresh(int version) async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) return false;
      final response = await _refreshDio.post<dynamic>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      if (response.statusCode != 200 || version != _sessionVersion) {
        return false;
      }
      await _tokenStorage.saveTokens(
        accessToken: response.data['accessToken'],
        refreshToken: response.data['refreshToken'],
      );
      return version == _sessionVersion;
    } catch (_) {
      return false;
    }
  }

  Future<void> endSession() async {
    _sessionVersion++;
    await _refreshFuture;
  }

  int get sessionVersion => _sessionVersion;

  Dio get dio => _dio;
}
