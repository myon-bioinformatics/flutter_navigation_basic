import 'package:flutter_application_1/shared/http/auth_matrix.dart';
import 'package:flutter_application_1/shared/http/request_draft.dart';
import 'package:flutter_application_1/shared/http/request_executor.dart';
import 'package:flutter_application_1/shared/mcp/mcp.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../tool/src/mock_auth.dart';
import '../../../tool/src/mock_mcp.dart';

void main() {
  group('McpSessionClient', () {
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
          requestTarget,
        }) {
          final result = auth.handle(
            method: method,
            path: path,
            headers: headers,
            query: query,
            requestTarget: requestTarget,
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

  test('support matrix still marks legacy MCP era', () {
    expect(McpProtocol.implementsCurrentOfficial, isFalse);
    expect(McpSupportMatrix.legacyMcpEra, isTrue);
  });
}
