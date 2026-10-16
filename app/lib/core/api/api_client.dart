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
  late final Dio
  _refreshDio; // Separate Dio for refresh to avoid interceptor loop
  final TokenStorage _tokenStorage;
  bool _isRefreshing = false;
  _RefreshLock? _refreshLock;

  ApiClient(this._tokenStorage) {
    print('🔵 Initializing API Client with base URL: ${AppConfig.apiBaseUrl}');
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: Duration(milliseconds: AppConfig.apiConnectTimeout),
        receiveTimeout: Duration(milliseconds: AppConfig.apiReceiveTimeout),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Separate Dio instance for refresh token calls (no interceptor)
    _refreshDio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: Duration(milliseconds: AppConfig.apiConnectTimeout),
        receiveTimeout: Duration(milliseconds: AppConfig.apiReceiveTimeout),
        headers: {'Content-Type': 'application/json'},
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
            // Don't retry multipart requests — file streams can't be re-read
            final isMultipart = error.requestOptions.data is FormData;
            if (isMultipart) {
              return handler.next(error);
            }

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
    // Prevent concurrent refresh attempts
    if (_isRefreshing) {
      // Wait for the ongoing refresh to complete
      await _refreshLock?.completer.future;
      return _refreshLock?.success ?? false;
    }

    _isRefreshing = true;
    final lock = _RefreshLock();
    _refreshLock = lock;

    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        lock.complete(false);
        return false;
      }

      // Use separate Dio instance to avoid interceptor loop
      final response = await _refreshDio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await _tokenStorage.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
        lock.complete(true);
        return true;
      }
      lock.complete(false);
      return false;
    } catch (e) {
      lock.complete(false);
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  Dio get dio => _dio;
}

class _RefreshLock {
  final completer = _Completer<bool>();
  bool? success;

  void complete(bool result) {
    success = result;
    completer.complete(result);
  }
}

class _Completer<T> {
  T? _value;
  bool _isCompleted = false;
  final List<void Function(T)> _callbacks = [];

  void complete(T value) {
    if (_isCompleted) return;
    _isCompleted = true;
    _value = value;
    for (final callback in _callbacks) {
      callback(value);
    }
  }

  Future<T> get future {
    if (_isCompleted) return Future.value(_value);
    final completer = _Completer<T>();
    _callbacks.add(completer.complete);
    return completer.future;
  }
}
