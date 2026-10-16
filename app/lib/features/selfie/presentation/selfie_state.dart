import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../data/selfie_repository.dart';
import '../domain/selfie.dart';
import '../../submission/presentation/submission_state.dart';
import '../../submission/domain/submission.dart';

final selfieStateProvider = StateNotifierProvider<SelfieNotifier, SelfieState>((
  ref,
) {
  final repository = ref.watch(selfieRepositoryProvider);
  return SelfieNotifier(repository, ref);
});

class SelfieState {
  final bool isLoading;
  final Selfie? selfie;
  final String? errorMessage;
  final bool isUploaded;

  SelfieState({
    this.isLoading = false,
    this.selfie,
    this.errorMessage,
    this.isUploaded = false,
  });

  SelfieState copyWith({
    bool? isLoading,
    Selfie? selfie,
    String? errorMessage,
    bool? isUploaded,
    bool clearError = false,
  }) {
    return SelfieState(
      isLoading: isLoading ?? this.isLoading,
      selfie: selfie ?? this.selfie,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isUploaded: isUploaded ?? this.isUploaded,
    );
  }
}

class SelfieNotifier extends StateNotifier<SelfieState> {
  final SelfieRepository _repository;
  final Ref _ref;

  SelfieNotifier(this._repository, this._ref) : super(SelfieState());

  Future<void> loadSelfie() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.getSelfie();

    if (result.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        selfie: result.selfie,
        isUploaded: result.selfie != null,
      );
    } else {
      state = state.copyWith(isLoading: false, isUploaded: false);
    }
  }

  Future<bool> uploadSelfie({required File file}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.uploadSelfie(file: file);

    if (result.isSuccess && result.selfie != null) {
      // Reload selfie to get the updated data
      await loadSelfie();

      // Clear selfie rejection from submission state
      _clearSelfieRejection();

      return true;
    } else {
      state = state.copyWith(isLoading: false, errorMessage: result.message);
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void reset() {
    state = SelfieState();
  }

  void _clearSelfieRejection() async {
    final submissionNotifier = _ref.read(submissionStateProvider.notifier);
    final currentSubmission = submissionNotifier.state.submission;

    if (currentSubmission?.rejectionDetails != null) {
      final rejectionDetails = currentSubmission!.rejectionDetails!;

      // Create new rejection details without selfie
      final updatedRejection = RejectionDetails(
        personalDetails: rejectionDetails.personalDetails,
        documents: rejectionDetails.documents,
        generalNotes: rejectionDetails.generalNotes,
      );

      // Check if all rejections are now cleared
      final hasAnyErrors =
          updatedRejection.hasPersonalDetailsErrors ||
          updatedRejection.hasDocumentErrors ||
          updatedRejection.hasSelfieErrors;

      // If all errors are cleared, call backend to reset submission
      if (!hasAnyErrors && currentSubmission.isRejected) {
        await submissionNotifier.resetSubmission();
      } else {
        // Create updated submission with remaining errors
        final updatedSubmission = Submission(
          id: currentSubmission.id,
          userId: currentSubmission.userId,
          status: currentSubmission.status,
          submittedAt: currentSubmission.submittedAt,
          reviewedAt: currentSubmission.reviewedAt,
          notes: currentSubmission.notes,
          rejectionDetails: updatedRejection,
        );

        // Update submission state
        submissionNotifier.state = submissionNotifier.state.copyWith(
          submission: updatedSubmission,
        );
      }
    }
  }
}
