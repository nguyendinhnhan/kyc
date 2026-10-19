import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyc_app/core/api/api_client.dart';
import 'package:kyc_app/features/submission/data/submission_repository.dart';
import 'api_client_test.dart' show MemoryTokens, Adapter, body;

class PendingTokens extends MemoryTokens {
  String? key;
  int generated = 0;
  @override
  Future<String> pendingSubmissionKey() async =>
      key ??= 'synthetic-attempt-${++generated}';
  @override
  Future<void> clearSubmissionKey() async {
    key = null;
  }
}

void main() {
  setUp(() => dotenv.testLoad(fileInput: 'API_BASE_URL=http://localhost:3000'));
  test(
    'submission retry after an uncertain response reuses the persisted key across repository instances',
    () async {
      final tokens = PendingTokens();
      final keys = <Object?>[];
      final dio = Dio()
        ..httpClientAdapter = Adapter((request) async {
          keys.add(request.headers['Idempotency-Key']);
          if (keys.length == 1) {
            throw DioException(
              requestOptions: request,
              type: DioExceptionType.receiveTimeout,
            );
          }
          return body(
            200,
            '{"submission":{"_id":"synthetic","userId":"owner","status":"submitted"}}',
          );
        });
      final client = ApiClient(tokens, dio: dio);
      expect(
        (await SubmissionRepository(client, tokens).submitKYC()).isSuccess,
        isFalse,
      );
      expect(tokens.key, isNotNull);
      expect(
        (await SubmissionRepository(client, tokens).submitKYC()).isSuccess,
        isTrue,
      );
      expect(keys[0], isNotNull);
      expect(keys[1], keys[0]);
      expect(tokens.key, isNull);
    },
  );
}
