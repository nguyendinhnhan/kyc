import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyc_app/core/api/api_client.dart';
import 'package:kyc_app/core/storage/token_storage.dart';

class MemoryTokens extends TokenStorage {
  String? access = 'old';
  String? refresh = 'refresh';
  @override
  Future<String?> getAccessToken() async => access;
  @override
  Future<String?> getRefreshToken() async => refresh;
  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    access = accessToken;
    refresh = refreshToken;
  }

  @override
  Future<void> clearTokens() async {
    access = null;
    refresh = null;
  }
}

class Adapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions) respond;
  Adapter(this.respond);
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? s,
    Future<void>? c,
  ) => respond(o);
  @override
  void close({bool force = false}) {}
}

ResponseBody body(int status, [String json = '{}']) => ResponseBody.fromString(
  json,
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);
void main() {
  setUp(() => dotenv.testLoad(fileInput: 'API_BASE_URL=http://localhost:3000'));
  test(
    'concurrent unauthorized reads share one refresh and both complete',
    () async {
      final gate = Completer<void>();
      var calls = 0;
      final dio = Dio()
        ..httpClientAdapter = Adapter(
          (o) async =>
              body(o.headers['Authorization'] == 'Bearer new' ? 200 : 401),
        );
      final refresh = Dio()
        ..httpClientAdapter = Adapter((o) async {
          calls++;
          await gate.future;
          return body(200, '{"accessToken":"new","refreshToken":"rotated"}');
        });
      final client = ApiClient(MemoryTokens(), dio: dio, refreshDio: refresh);
      final requests = Future.wait([
        client.dio.get('/one'),
        client.dio.get('/two'),
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      gate.complete();
      expect((await requests).map((r) => r.statusCode), [200, 200]);
      expect(calls, 1);
    },
  );
  test('invalid login is never refreshed or automatically repeated', () async {
    var calls = 0;
    var refreshes = 0;
    final dio = Dio()
      ..httpClientAdapter = Adapter((o) async {
        calls++;
        return body(401);
      });
    final refresh = Dio()
      ..httpClientAdapter = Adapter((o) async {
        refreshes++;
        return body(401);
      });
    final client = ApiClient(MemoryTokens(), dio: dio, refreshDio: refresh);
    await expectLater(
      client.dio.post('/auth/login'),
      throwsA(isA<DioException>()),
    );
    expect(calls, 1);
    expect(refreshes, 0);
  });
  test('a retried unauthorized read stops after one refresh', () async {
    var refreshes = 0;
    final dio = Dio()..httpClientAdapter = Adapter((o) async => body(401));
    final refresh = Dio()
      ..httpClientAdapter = Adapter((o) async {
        refreshes++;
        return body(200, '{"accessToken":"new","refreshToken":"rotated"}');
      });
    final client = ApiClient(MemoryTokens(), dio: dio, refreshDio: refresh);
    await expectLater(client.dio.get('/private'), throwsA(isA<DioException>()));
    expect(refreshes, 1);
  });
}
