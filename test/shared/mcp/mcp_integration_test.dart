import 'package:flutter_application_1/shared/http/auth_matrix.dart';
import 'package:flutter_application_1/shared/http/request_draft.dart';
import 'package:flutter_application_1/shared/http/request_field.dart';
import 'package:flutter_application_1/shared/http/request_executor.dart';
import 'package:flutter_application_1/shared/mcp/mcp.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/shared/http/mock_auth.dart';
import '../../../tool/src/mock_mcp.dart';

void main() {
  group('McpSessionClient', () {

    test('modern echo demo over FoundationHandlerTransport', () async {
      final client = McpSessionClient(
        transport: FoundationHandlerTransport(McpFoundationHandler()),
      );
      final result = await client.runModernEchoDemo(text: 'modern-ping');
      expect(result.ok, isTrue);
      expect(result.sessionId, isNull);
      final content = (result.lastResponse!.result as Map)['content'] as List;
      expect((content.first as Map)['text'], 'modern-ping');
    });

    test('modern echo demo over MockMcpRoutes in-process transport', () async {
      final routes = MockMcpRoutes(
        handler: McpFoundationHandler(sessionIdFactory: () => 'sess-modern-demo'),
      );
      final client = McpSessionClient(
        transport: InProcessMcpTransport(
          dispatch: ({
            required method,
            required path,
            required headers,
            required rawBody,
          }) =>
              routes.handle(
            method: method,
            path: path,
            headers: headers,
            rawBody: rawBody,
          ),
        ),
      );
      final result = await client.runModernEchoDemo(text: 'modern-http');
      expect(result.ok, isTrue);
      expect(result.sessionId, isNull);
      final content = (result.lastResponse!.result as Map)['content'] as List;
      expect((content.first as Map)['text'], 'modern-http');
    });

    test('echo demo over FoundationHandlerTransport', () async {
      final client = McpSessionClient(
        transport: FoundationHandlerTransport(McpFoundationHandler()),
      );
      final result = await client.runEchoDemo(text: 'ping');
      expect(result.ok, isTrue);
      expect(result.sessionId, isNotNull);
      expect(result.log, isNotEmpty);
      final content = (result.lastResponse!.result as Map)['content'] as List;
      expect((content.first as Map)['text'], 'ping');
    });

    test('echo demo over MockMcpRoutes in-process transport', () async {
      final routes = MockMcpRoutes(
        handler: McpFoundationHandler(sessionIdFactory: () => 'sess-demo'),
      );
      final client = McpSessionClient(
        transport: InProcessMcpTransport(
          dispatch: ({
            required method,
            required path,
            required headers,
            required rawBody,
          }) =>
              routes.handle(
            method: method,
            path: path,
            headers: headers,
            rawBody: rawBody,
          ),
        ),
      );
      final result = await client.runEchoDemo(text: 'via-http-mock');
      expect(result.ok, isTrue);
      expect(result.sessionId, 'sess-demo');
    });
  });

  group('AuthMatrixScenario + MockAuthRequestExecutor', () {
    late MockAuthRequestExecutor executor;

    setUp(() {
      final auth = MockAuthHandler();
      executor = MockAuthRequestExecutor(
        handler: ({
          required method,
          required path,
          required headers,
          required query,
          required queryPairs,
          requestTarget,
          body,
        }) {
          final result = auth.handle(
            method: method,
            path: path,
            headers: headers,
            query: query,
            requestTarget: requestTarget,
            body: body,
            queryPairs: queryPairs,
          );
          if (result == null) return null;
          return (
            statusCode: result.statusCode,
            body: result.body,
            headers: result.headers,
          );
        },
        hmacSecret: MockAuthDemo.hmacSecret,
        hmacKeyId: MockAuthDemo.hmacKeyId,
      );
    });

    test('bearer valid / expired / wrong audience map to expected statuses', () {
      const base = 'http://127.0.0.1:8787';
      final valid = executor.execute(
        AuthMatrixScenario.bearer.applyTo(const RequestDraft(), baseUrl: base),
        scenario: AuthMatrixScenario.bearer,
      );
      expect(valid.statusCode, 200);

      final expired = executor.execute(
        AuthMatrixScenario.bearerExpired
            .applyTo(const RequestDraft(), baseUrl: base),
        scenario: AuthMatrixScenario.bearerExpired,
      );
      expect(expired.statusCode, 401);

      final wrong = executor.execute(
        AuthMatrixScenario.bearerWrongAudience
            .applyTo(const RequestDraft(), baseUrl: base),
        scenario: AuthMatrixScenario.bearerWrongAudience,
      );
      expect(wrong.statusCode, anyOf(401, 403));
    });

    test('runMatrix covers all non-none scenarios without throwing', () {
      final results = executor.runMatrix();
      expect(results, isNotEmpty);
      expect(
        results.map((e) => e.scenario),
        isNot(contains(AuthMatrixScenario.none)),
      );
      for (final entry in results) {
        expect(entry.result.statusCode, greaterThanOrEqualTo(200));
      }
    });
  });


  group('Auth matrix negatives + digest/HMAC binding', () {
    late MockAuthRequestExecutor executor;
    late MockAuthHandler auth;

    setUp(() {
      auth = MockAuthHandler();
      executor = MockAuthRequestExecutor(
        handler: ({
          required method,
          required path,
          required headers,
          required query,
          required queryPairs,
          requestTarget,
          body,
        }) {
          final result = auth.handle(
            method: method,
            path: path,
            headers: headers,
            query: query,
            requestTarget: requestTarget,
            body: body,
            queryPairs: queryPairs,
          );
          if (result == null) return null;
          return (
            statusCode: result.statusCode,
            body: result.body,
            headers: result.headers,
          );
        },
        hmacSecret: MockAuthDemo.hmacSecret,
        hmacKeyId: MockAuthDemo.hmacKeyId,
        digestUsername: MockAuthDemo.basicUser,
        digestPassword: MockAuthDemo.basicPassword,
      );
    });

    test('digest challenge-response succeeds; wrong URI fails', () {
      const base = 'http://127.0.0.1:8787';
      final ok = executor.execute(
        AuthMatrixScenario.digest.applyTo(const RequestDraft(), baseUrl: base),
        scenario: AuthMatrixScenario.digest,
      );
      expect(ok.statusCode, 200);

      final challengeOnly = executor.execute(
        AuthMatrixScenario.digestChallengeOnly
            .applyTo(const RequestDraft(), baseUrl: base),
        scenario: AuthMatrixScenario.digestChallengeOnly,
      );
      expect(challengeOnly.statusCode, 401);
      expect(
        challengeOnly.headers.keys.map((k) => k.toLowerCase()),
        contains('www-authenticate'),
      );
    });


    test('two consecutive Digest executions succeed; replay still fails', () {
      const base = 'http://127.0.0.1:8787';
      final draft =
          AuthMatrixScenario.digest.applyTo(const RequestDraft(), baseUrl: base);

      final first = executor.execute(draft, scenario: AuthMatrixScenario.digest);
      expect(first.statusCode, 200, reason: first.body.toString());
      expect(first.executionPath, 'digest-retry');

      final second =
          executor.execute(draft, scenario: AuthMatrixScenario.digest);
      expect(second.statusCode, 200, reason: second.body.toString());
      expect(second.executionPath, 'digest-retry');

      // Same Authorization header replayed against the mock is rejected.
      final wire = second.wireDraft!;
      final replay = executor.execute(wire);
      expect(replay.statusCode, 401);
      expect(replay.body['reason'], 'digest_replay');
    });

    test('HMAC binds ordered query + body; tamper / replay / bad secret fail', () {
      const base = 'http://127.0.0.1:8787';
      final draft = AuthMatrixScenario.hmac
          .applyTo(const RequestDraft(), baseUrl: base)
          .copyWith(
            query: const [
              RequestField(id: 'q1', name: 'foo', value: '1'),
              RequestField(id: 'q2', name: 'foo', value: '2'),
              RequestField(id: 'q3', name: 'bar', value: 'x'),
            ],
            bodyMode: RequestBodyMode.raw,
            rawBody: '{"hello":"world"}',
          );

      final ok = executor.execute(draft, scenario: AuthMatrixScenario.hmac);
      expect(ok.statusCode, 200, reason: ok.body.toString());
      expect(ok.requestTarget, contains('foo=1'));
      expect(ok.requestTarget, contains('foo=2'));

      // Bad secret
      final badSecret = MockAuthRequestExecutor(
        handler: executor.handler,
        hmacSecret: 'wrong-secret',
        hmacKeyId: MockAuthDemo.hmacKeyId,
      );
      final bad = badSecret.execute(draft, scenario: AuthMatrixScenario.hmac);
      expect(bad.statusCode, 401);

      // Replay same nonce/timestamp/signature (timestamp must be within skew).
      final now = (DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000).toString();
      final signed = executor.signHmac(
        draft,
        timestamp: now,
        nonce: 'fixed-nonce',
      );
      final first = executor.execute(signed);
      expect(first.statusCode, 200);
      final replay = executor.execute(signed);
      expect(replay.statusCode, 401);
      expect(replay.body['reason'], 'replay');

      // Tamper query after signing
      final tampered = signed.copyWith(
        query: [
          ...signed.query,
          const RequestField(id: 'evil', name: 'evil', value: '1'),
        ],
      );
      // Re-signing is skipped when scenario is null — send as-is.
      final tamperedResult = executor.execute(tampered);
      expect(tamperedResult.statusCode, 401);
    });

    test('rejected initialized notification stops echo demo', () async {
      final client = McpSessionClient(
        transport: _RejectInitializedTransport(),
      );
      final result = await client.runEchoDemo(text: 'nope');
      expect(result.ok, isFalse);
      expect(
        result.log.any((line) => line.contains('rejected')),
        isTrue,
      );
    });

    test('failed initialize does not retain session id', () async {
      final client = McpSessionClient(
        transport: _FailInitializeWithSessionTransport(),
      );
      final init = await client.initialize();
      expect(init.isError, isTrue);
      expect(client.sessionId, isNull);
    });
  });
  test('support matrix still marks legacy MCP era', () {
    expect(McpProtocol.implementsCurrentOfficial, isTrue);
    expect(McpSupportMatrix.legacyMcpEra, isTrue);
    expect(McpSupportMatrix.currentOfficialEra, isTrue);
  });
}


class _RejectInitializedTransport implements McpStreamableTransport {
  String? _session;

  @override
  Future<McpTransportResponse> post({
    required Map<String, String> headers,
    required String body,
  }) async {
    final request = JsonRpcRequest.tryParse(body);
    if (request == null) {
      return const McpTransportResponse(statusCode: 400, headers: {}, body: {});
    }
    if (request.method == 'initialize') {
      _session = 'sess-reject-init';
      return McpTransportResponse(
        statusCode: 200,
        headers: {McpProtocol.sessionIdHeader: _session!},
        body: JsonRpcResponse.result(
          id: request.id,
          result: {
            'protocolVersion': McpProtocol.specificationVersion,
            'capabilities': <String, Object?>{},
            'serverInfo': {'name': 't', 'version': '1'},
          },
        ).toJson(),
      );
    }
    if (request.method == 'notifications/initialized') {
      return const McpTransportResponse(
        statusCode: 404,
        headers: {},
        body: {'error': 'session_invalid'},
      );
    }
    return const McpTransportResponse(
      statusCode: 500,
      headers: {},
      body: {'error': 'unexpected'},
    );
  }
}

class _FailInitializeWithSessionTransport implements McpStreamableTransport {
  @override
  Future<McpTransportResponse> post({
    required Map<String, String> headers,
    required String body,
  }) async {
    final request = JsonRpcRequest.tryParse(body);
    return McpTransportResponse(
      statusCode: 401,
      headers: {McpProtocol.sessionIdHeader: 'should-not-keep'},
      body: JsonRpcResponse.result(
        id: request?.id,
        result: {'protocolVersion': McpProtocol.specificationVersion},
      ).toJson(),
    );
  }
}
