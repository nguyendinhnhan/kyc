import '../../../core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../domain/submission.dart';

final submissionRepositoryProvider = Provider<SubmissionRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SubmissionRepository(apiClient, ref.watch(tokenStorageProvider));
});

class SubmissionRepository {
  final ApiClient _apiClient;

  final TokenStorage _storage;

  SubmissionRepository(this._apiClient, [TokenStorage? storage])
    : _storage = storage ?? TokenStorage();

  Future<SubmissionResult> submitKYC() async {
    try {
      final version = _apiClient.sessionVersion;
      final key = await _storage.pendingSubmissionKey();
      final response = await _apiClient.dio.post(
        '/user/submit',
        data: {},
        options: Options(
          headers: {'Idempotency-Key': key},
          extra: {'sessionVersion': version},
        ),
      );

      if (response.statusCode == 200) {
        await _storage.clearSubmissionKey();
        final submission = Submission.fromJson(response.data['submission']);
        return SubmissionResult.success(
          message: response.data['message'] ?? 'KYC submitted successfully',
          submission: submission,
        );
      }

      return SubmissionResult.error(
        message: response.data['error'] ?? 'Failed to submit KYC',
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final errorMsg = data is Map
          ? (data['error']?.toString() ?? 'Failed to submit KYC')
          : 'Failed to submit KYC';
      return SubmissionResult.error(message: errorMsg);
    } catch (e) {
      return SubmissionResult.error(message: 'An unexpected error occurred');
    }
  }

  Future<SubmissionResult> getSubmission() async {
    try {
      final response = await _apiClient.dio.get('/user/submission');

      if (response.statusCode == 200) {
        if (response.data['submission'] == null) {
          return SubmissionResult.success(
            message: 'No submission found',
            submission: null,
          );
        }

        final submission = Submission.fromJson(response.data['submission']);
        return SubmissionResult.success(
          message: 'Submission retrieved successfully',
          submission: submission,
        );
      }

      return SubmissionResult.error(
        message:
            response.data['error']?.toString() ??
            'Failed to retrieve submission',
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final errorMsg = data is Map
          ? (data['error']?.toString() ?? 'Failed to retrieve submission')
          : 'Failed to retrieve submission';
      return SubmissionResult.error(message: errorMsg);
    } catch (e) {
      return SubmissionResult.error(message: 'An unexpected error occurred');
    }
  }

  Future<SubmissionResult> resetSubmission() => submitKYC();
}

class SubmissionResult {
  final bool isSuccess;
  final String message;
  final Submission? submission;

  SubmissionResult._({
    required this.isSuccess,
    required this.message,
    this.submission,
  });

  factory SubmissionResult.success({
    required String message,
    Submission? submission,
  }) {
    return SubmissionResult._(
      isSuccess: true,
      message: message,
      submission: submission,
    );
  }

  factory SubmissionResult.error({required String message}) {
    return SubmissionResult._(isSuccess: false, message: message);
  }
}
