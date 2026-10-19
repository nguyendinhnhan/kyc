import 'package:kyc_app/features/personal_details/domain/personal_details.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyc_app/core/api/api_client.dart';
import 'package:kyc_app/features/auth/data/auth_repository.dart';
import 'package:kyc_app/features/auth/domain/user.dart';
import 'package:kyc_app/features/auth/presentation/auth_state.dart';
import 'package:kyc_app/features/submission/domain/submission.dart';
import 'package:kyc_app/features/submission/presentation/submission_state.dart';
import 'package:kyc_app/features/personal_details/data/personal_details_repository.dart';
import 'package:kyc_app/features/personal_details/presentation/personal_details_state.dart';
import 'api_client_test.dart' show MemoryTokens;

class FakeAuth extends AuthRepository {
  FakeAuth() : super(ApiClient(MemoryTokens()), MemoryTokens());
  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async => AuthResult.success(
    message: 'ok',
    user: User(id: email, email: email, fullName: 'Synthetic User'),
  );
  @override
  Future<AuthResult> logout() async => AuthResult.success(message: 'ok');
}

class PendingDetails extends PersonalDetailsRepository {
  final pending = Completer<PersonalDetailsResult>();
  PendingDetails() : super(ApiClient(MemoryTokens()));
  @override
  Future<PersonalDetailsResult> getPersonalDetails() => pending.future;
}

void main() {
  setUp(() => dotenv.testLoad(fileInput: 'API_BASE_URL=http://localhost:3000'));
  test(
    'logout clears cached submission before another account logs in',
    () async {
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(FakeAuth())],
      );
      addTearDown(container.dispose);
      final auth = container.read(authStateProvider.notifier);
      await auth.login(email: 'first', password: 'synthetic');
      container
          .read(submissionStateProvider.notifier)
          .updateSubmission(
            Submission(
              id: 'first-submission',
              userId: 'first',
              status: 'approved',
            ),
          );
      await auth.logout();
      expect(container.read(submissionStateProvider).submission, isNull);
      await auth.login(email: 'second', password: 'synthetic');
      expect(container.read(submissionStateProvider).submission, isNull);
    },
  );
  test(
    'an old account response cannot repopulate details after logout',
    () async {
      final repository = PendingDetails();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuth()),
          personalDetailsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final auth = container.read(authStateProvider.notifier);
      await auth.login(email: 'first', password: 'synthetic');
      final loading = container
          .read(personalDetailsStateProvider.notifier)
          .loadPersonalDetails();
      await auth.logout();
      expect(container.read(personalDetailsStateProvider).details, isNull);
      repository.pending.complete(
        PersonalDetailsResult.success(
          message: 'ok',
          personalDetails: PersonalDetails(
            dateOfBirth: '1990-01-01',
            nationality: 'US',
            phone: '+1234567890',
            address: Address(
              street: 'Synthetic',
              city: 'City',
              state: 'State',
              postalCode: '12345',
              country: 'US',
            ),
          ),
        ),
      );
      await loading;
      expect(container.read(personalDetailsStateProvider).details, isNull);
    },
  );
}
