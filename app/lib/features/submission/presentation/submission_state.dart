import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/submission_repository.dart';
import '../domain/submission.dart';

final submissionStateProvider = StateNotifierProvider<SubmissionNotifier, SubmissionState>((ref) {
  final repository = ref.watch(submissionRepositoryProvider);
  return SubmissionNotifier(repository);
});

class SubmissionState {
  final bool isLoading;
  final Submission? submission;
  final String? errorMessage;
  final bool isSubmitted;

  SubmissionState({
    this.isLoading = false,
    this.submission,
    this.errorMessage,
    this.isSubmitted = false,
  });

  SubmissionState copyWith({
    bool? isLoading,
    Submission? submission,
    String? errorMessage,
    bool? isSubmitted,
    bool clearError = false,
  }) {
    return SubmissionState(
      isLoading: isLoading ?? this.isLoading,
      submission: submission ?? this.submission,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSubmitted: isSubmitted ?? this.isSubmitted,
    );
  }
}

class SubmissionNotifier extends StateNotifier<SubmissionState> {
  final SubmissionRepository _repository;

  SubmissionNotifier(this._repository) : super(SubmissionState());

  Future<void> loadSubmission() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.getSubmission();

    if (result.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        submission: result.submission,
        isSubmitted: result.submission?.isSubmitted ?? false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        isSubmitted: false,
      );
    }
  }

  Future<bool> submitKYC() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.submitKYC();

    if (result.isSuccess && result.submission != null) {
      // Reload submission to get the updated data
      await loadSubmission();
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
    state = SubmissionState();
  }
}
