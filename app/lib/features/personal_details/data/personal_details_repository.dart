import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../domain/personal_details.dart';

final personalDetailsRepositoryProvider = Provider<PersonalDetailsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PersonalDetailsRepository(apiClient);
});

class PersonalDetailsRepository {
  final ApiClient _apiClient;

  PersonalDetailsRepository(this._apiClient);

  Future<PersonalDetailsResult> savePersonalDetails({
    required String dateOfBirth,
    required String nationality,
    required String phone,
    required Address address,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/user/personal-details',
        data: {
          'dateOfBirth': dateOfBirth,
          'nationality': nationality,
          'phone': phone,
          'address': address.toJson(),
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final personalDetails = PersonalDetails.fromJson(
          response.data['personalDetails'],
        );
        return PersonalDetailsResult.success(
          message: response.data['message'] ?? 'Personal details saved',
          personalDetails: personalDetails,
        );
      }

      return PersonalDetailsResult.error(
        message: response.data['error'] ?? 'Failed to save personal details',
      );
    } on DioException catch (e) {
      return PersonalDetailsResult.error(
        message: e.response?.data['error'] ?? 'Failed to save personal details',
      );
    } catch (e) {
      return PersonalDetailsResult.error(
        message: 'An unexpected error occurred',
      );
    }
  }

  Future<PersonalDetailsResult> getPersonalDetails() async {
    try {
      final response = await _apiClient.dio.get('/user/personal-details');

      if (response.statusCode == 200) {
        final personalDetails = PersonalDetails.fromJson(
          response.data['personalDetails'],
        );
        return PersonalDetailsResult.success(
          message: 'Personal details retrieved',
          personalDetails: personalDetails,
        );
      }

      return PersonalDetailsResult.error(
        message: response.data['error'] ?? 'Failed to retrieve personal details',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return PersonalDetailsResult.error(
          message: 'Personal details not found',
        );
      }
      return PersonalDetailsResult.error(
        message: e.response?.data['error'] ?? 'Failed to retrieve personal details',
      );
    } catch (e) {
      return PersonalDetailsResult.error(
        message: 'An unexpected error occurred',
      );
    }
  }
}

class PersonalDetailsResult {
  final bool isSuccess;
  final String message;
  final PersonalDetails? personalDetails;

  PersonalDetailsResult._({
    required this.isSuccess,
    required this.message,
    this.personalDetails,
  });

  factory PersonalDetailsResult.success({
    required String message,
    PersonalDetails? personalDetails,
  }) {
    return PersonalDetailsResult._(
      isSuccess: true,
      message: message,
      personalDetails: personalDetails,
    );
  }

  factory PersonalDetailsResult.error({required String message}) {
    return PersonalDetailsResult._(
      isSuccess: false,
      message: message,
    );
  }
}
