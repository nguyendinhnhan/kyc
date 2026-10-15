import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../data/selfie_repository.dart';
import '../domain/selfie.dart';

final selfieStateProvider = StateNotifierProvider<SelfieNotifier, SelfieState>((ref) {
  final repository = ref.watch(selfieRepositoryProvider);
  return SelfieNotifier(repository);
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

  SelfieNotifier(this._repository) : super(SelfieState());

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
      state = state.copyWith(
        isLoading: false,
        isUploaded: false,
      );
    }
  }

  Future<bool> uploadSelfie({
    required File file,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.uploadSelfie(
      file: file,
    );

    if (result.isSuccess && result.selfie != null) {
      // Reload selfie to get the updated data
      await loadSelfie();
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
    state = SelfieState();
  }
}
