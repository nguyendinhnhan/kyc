import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../domain/user.dart';

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final User? user;
  final String? errorMessage;
  final String? successMessage;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.errorMessage,
    this.successMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    User? user,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState());

  Future<void> checkAuthStatus() async {
    final isAuthenticated = await _repository.isAuthenticated();
    state = state.copyWith(isAuthenticated: isAuthenticated);
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.login(email: email, password: password);

    if (result.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: result.user,
      );
      return true;
    } else {
      state = state.copyWith(isLoading: false, errorMessage: result.message);
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.register(
      email: email,
      password: password,
      fullName: fullName,
    );

    if (result.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: null,
        successMessage: 'Registration successful! Please login.',
      );
      return true;
    } else {
      state = state.copyWith(isLoading: false, errorMessage: result.message);
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _repository.logout();
    state = AuthState(); // Reset to initial state
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void clearSuccessMessage() {
    state = state.copyWith(clearSuccess: true);
  }
}
