import '../../auth/presentation/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../data/selfie_repository.dart';
import '../domain/selfie.dart';
import '../../submission/presentation/submission_state.dart';

final selfieStateProvider = StateNotifierProvider<SelfieNotifier, SelfieState>((
  ref,
) {
  ref.watch(authStateProvider.select((state) => state.user?.id));
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

    if (!mounted) return;

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

    if (!mounted) return false;

    if (result.isSuccess && result.selfie != null) {
      // Reload selfie to get the updated data
      await loadSelfie();
      if (!mounted) return false;

      // Refresh server-owned workflow status after the edit.
      await _ref.read(submissionStateProvider.notifier).loadSubmission();

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
}
