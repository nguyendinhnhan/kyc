import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/personal_details_repository.dart';
import '../domain/personal_details.dart';

final personalDetailsStateProvider = StateNotifierProvider<PersonalDetailsNotifier, PersonalDetailsState>((ref) {
  final repository = ref.watch(personalDetailsRepositoryProvider);
  return PersonalDetailsNotifier(repository);
});

class PersonalDetailsState {
  final bool isLoading;
  final PersonalDetails? details;
  final String? errorMessage;
  final bool isSaved;

  PersonalDetailsState({
    this.isLoading = false,
    this.details,
    this.errorMessage,
    this.isSaved = false,
  });

  PersonalDetailsState copyWith({
    bool? isLoading,
    PersonalDetails? details,
    String? errorMessage,
    bool? isSaved,
    bool clearError = false,
  }) {
    return PersonalDetailsState(
      isLoading: isLoading ?? this.isLoading,
      details: details ?? this.details,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

class PersonalDetailsNotifier extends StateNotifier<PersonalDetailsState> {
  final PersonalDetailsRepository _repository;

  PersonalDetailsNotifier(this._repository) : super(PersonalDetailsState());

  Future<void> loadPersonalDetails() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.getPersonalDetails();

    if (result.isSuccess && result.personalDetails != null) {
      state = state.copyWith(
        isLoading: false,
        details: result.personalDetails,
        isSaved: true,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        isSaved: false,
        // Don't show error for 404 (no details yet)
        errorMessage: result.message.contains('not found') ? null : result.message,
      );
    }
  }

  Future<bool> savePersonalDetails({
    required String dateOfBirth,
    required String nationality,
    required String phone,
    required Address address,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.savePersonalDetails(
      dateOfBirth: dateOfBirth,
      nationality: nationality,
      phone: phone,
      address: address,
    );

    if (result.isSuccess && result.personalDetails != null) {
      state = state.copyWith(
        isLoading: false,
        details: result.personalDetails,
        isSaved: true,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.message,
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void reset() {
    state = PersonalDetailsState();
  }
}
