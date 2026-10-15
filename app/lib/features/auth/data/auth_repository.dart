import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthRepository(apiClient, tokenStorage);
});

class AuthRepository {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  AuthRepository(this._apiClient, this._tokenStorage);

  Future<AuthResult> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      print('🔵 Registering user: $email');
      print('🔵 API URL: ${_apiClient.dio.options.baseUrl}/auth/register');
      
      final response = await _apiClient.dio.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'fullName': fullName,
        },
      );

      print('✅ Register response: ${response.statusCode}');
      print('✅ Response data: ${response.data}');

      if (response.statusCode == 201) {
        return AuthResult.success(
          message: response.data['message'] ?? 'Registration successful',
        );
      }

      return AuthResult.error(
        message: response.data['error'] ?? 'Registration failed',
      );
    } on DioException catch (e) {
      print('❌ Register DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      if (e.response?.statusCode == 409) {
        return AuthResult.error(message: 'Email already registered');
      }
      return AuthResult.error(
        message: e.response?.data['error'] ?? 'Registration failed',
      );
    } catch (e) {
      print('❌ Register error: $e');
      return AuthResult.error(message: 'An unexpected error occurred');
    }
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔵 Logging in user: $email');
      print('🔵 API URL: ${_apiClient.dio.options.baseUrl}/auth/login');
      
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      print('✅ Login response: ${response.statusCode}');
      print('✅ Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        await _tokenStorage.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );

        final user = User.fromJson(data['user']);
        return AuthResult.success(
          message: data['message'] ?? 'Login successful',
          user: user,
        );
      }

      return AuthResult.error(
        message: response.data['error'] ?? 'Login failed',
      );
    } on DioException catch (e) {
      print('❌ Login DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      if (e.response?.statusCode == 401) {
        return AuthResult.error(message: 'Invalid email or password');
      }
      return AuthResult.error(
        message: e.response?.data['error'] ?? 'Login failed',
      );
    } catch (e) {
      print('❌ Login error: $e');
      return AuthResult.error(message: 'An unexpected error occurred');
    }
  }

  Future<AuthResult> logout() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        await _tokenStorage.clearTokens();
        return AuthResult.success(message: 'Logged out successfully');
      }

      final response = await _apiClient.dio.post(
        '/auth/logout',
        data: {'refreshToken': refreshToken},
      );

      await _tokenStorage.clearTokens();

      if (response.statusCode == 200) {
        return AuthResult.success(
          message: response.data['message'] ?? 'Logged out successfully',
        );
      }

      return AuthResult.error(
        message: response.data['error'] ?? 'Logout failed',
      );
    } on DioException catch (e) {
      // Even if API call fails, clear tokens locally
      await _tokenStorage.clearTokens();
      return AuthResult.error(
        message: e.response?.data['error'] ?? 'Logout failed',
      );
    } catch (e) {
      await _tokenStorage.clearTokens();
      return AuthResult.error(message: 'An unexpected error occurred');
    }
  }

  Future<bool> isAuthenticated() async {
    return await _tokenStorage.hasTokens();
  }
}

class AuthResult {
  final bool isSuccess;
  final String message;
  final User? user;

  AuthResult._({
    required this.isSuccess,
    required this.message,
    this.user,
  });

  factory AuthResult.success({required String message, User? user}) {
    return AuthResult._(
      isSuccess: true,
      message: message,
      user: user,
    );
  }

  factory AuthResult.error({required String message}) {
    return AuthResult._(
      isSuccess: false,
      message: message,
    );
  }
}
