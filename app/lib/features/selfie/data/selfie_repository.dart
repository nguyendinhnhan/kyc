import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../../core/api/api_client.dart';
import '../domain/selfie.dart';

final selfieRepositoryProvider = Provider<SelfieRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SelfieRepository(apiClient);
});

class SelfieRepository {
  final ApiClient _apiClient;

  SelfieRepository(this._apiClient);

  Future<SelfieResult> uploadSelfie({
    required File file,
  }) async {
    try {
      // Create multipart form data
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final response = await _apiClient.dio.post(
        '/user/selfie',
        data: formData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final selfie = Selfie.fromJson(
          response.data['selfie'],
        );
        return SelfieResult.success(
          message: response.data['message'] ?? 'Selfie uploaded successfully',
          selfie: selfie,
        );
      }

      return SelfieResult.error(
        message: response.data['error'] ?? 'Failed to upload selfie',
      );
    } on DioException catch (e) {
      return SelfieResult.error(
        message: e.response?.data['error'] ?? 'Failed to upload selfie',
      );
    } catch (e) {
      return SelfieResult.error(
        message: 'An unexpected error occurred',
      );
    }
  }

  Future<SelfieResult> getSelfie() async {
    try {
      final response = await _apiClient.dio.get('/user/selfie');

      if (response.statusCode == 200) {
        if (response.data['selfie'] == null) {
          return SelfieResult.success(
            message: 'No selfie found',
            selfie: null,
          );
        }

        final selfie = Selfie.fromJson(
          response.data['selfie'],
        );
        return SelfieResult.success(
          message: 'Selfie retrieved successfully',
          selfie: selfie,
        );
      }

      return SelfieResult.error(
        message: response.data['error'] ?? 'Failed to retrieve selfie',
      );
    } on DioException catch (e) {
      return SelfieResult.error(
        message: e.response?.data['error'] ?? 'Failed to retrieve selfie',
      );
    } catch (e) {
      return SelfieResult.error(
        message: 'An unexpected error occurred',
      );
    }
  }
}

class SelfieResult {
  final bool isSuccess;
  final String message;
  final Selfie? selfie;

  SelfieResult._({
    required this.isSuccess,
    required this.message,
    this.selfie,
  });

  factory SelfieResult.success({
    required String message,
    Selfie? selfie,
  }) {
    return SelfieResult._(
      isSuccess: true,
      message: message,
      selfie: selfie,
    );
  }

  factory SelfieResult.error({required String message}) {
    return SelfieResult._(
      isSuccess: false,
      message: message,
    );
  }
}
