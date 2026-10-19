import '../../auth/presentation/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/submission_repository.dart';
import '../domain/submission.dart';

final submissionStateProvider =
    StateNotifierProvider<SubmissionNotifier, SubmissionState>((ref) {
      ref.watch(authStateProvider.select((state) => state.user?.id));
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
    bool clearSubmission = false,
  }) {
    return SubmissionState(
      isLoading: isLoading ?? this.isLoading,
      submission: clearSubmission ? null : (submission ?? this.submission),
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

    if (!mounted) return;

    if (result.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        submission: result.submission,
        clearSubmission: result.submission == null,
        isSubmitted: result.submission?.isSubmitted ?? false,
      );
    } else {
      state = state.copyWith(isLoading: false, isSubmitted: false);
    }
  }

  Future<bool> submitKYC() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.submitKYC();

    if (!mounted) return false;

    if (result.isSuccess && result.submission != null) {
      // Reload submission to get the updated data
      await loadSubmission();
      return true;
    } else {
      state = state.copyWith(isLoading: false, errorMessage: result.message);
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Update the submission locally (e.g., to clear rejection fields after user edits).
  void updateSubmission(Submission submission) {
    state = state.copyWith(
      submission: submission,
      isSubmitted: submission.isSubmitted,
    );
  }

  Future<void> resetSubmission() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.resetSubmission();
    if (!mounted) return;

    if (result.isSuccess && result.submission != null) {
      state = state.copyWith(
        isLoading: false,
        submission: result.submission,
        clearSubmission: result.submission == null,
        isSubmitted: result.submission!.isSubmitted,
      );
    } else {
      state = state.copyWith(isLoading: false, errorMessage: result.message);
    }
  }

  void reset() {
    state = SubmissionState();
  }
}
