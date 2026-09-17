import 'dart:convert';

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
  test('support matrix marks dual-era MCP as implemented', () {
    expect(McpProtocol.implementsCurrentOfficial, isTrue);
    expect(McpSupportMatrix.legacyMcpEra, isTrue);
    expect(McpSupportMatrix.currentOfficialEra, isTrue);
    expect(
      McpSupportMatrix.currentOfficialVersion,
      McpProtocol.currentOfficialVersion,
    );
  });

  test('FoundationHandlerTransport modern unknown → HTTP 404', () async {
    final transport = FoundationHandlerTransport(McpFoundationHandler());
    final response = await transport.post(
      headers: mcpStreamableHeaders(
        protocolVersion: McpProtocol.currentOfficialVersion,
        method: 'totally/unknown',
      ),
      body: jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'totally/unknown',
        'params': {
          '_meta': {
            'io.modelcontextprotocol/protocolVersion':
                McpProtocol.currentOfficialVersion,
            'io.modelcontextprotocol/clientInfo': {
              'name': 't',
              'version': '0',
            },
            'io.modelcontextprotocol/clientCapabilities': <String, Object?>{},
          },
        },
      }),
    );
    expect(response.statusCode, 404);
    final body = response.body as Map;
    expect((body['error'] as Map)['code'], JsonRpcErrorCode.methodNotFound);
    expect(
      response.headers[McpProtocol.protocolVersionHeader],
      McpProtocol.currentOfficialVersion,
    );
  });

  test('FoundationHandlerTransport modern envelope failures → HTTP 400',
      () async {
    final transport = FoundationHandlerTransport(McpFoundationHandler());

    Future<McpTransportResponse> post({
      required Map<String, String> headers,
      required Map<String, Object?> body,
    }) {
      return transport.post(headers: headers, body: jsonEncode(body));
    }

    // Header-only current-official + unknown method (no _meta).
    final headerOnly = await post(
      headers: {
        McpProtocol.protocolVersionHeader: McpProtocol.currentOfficialVersion,
        McpProtocol.methodHeader: 'totally/unknown',
      },
      body: {
        'jsonrpc': '2.0',
        'id': 10,
        'method': 'totally/unknown',
      },
    );
    expect(headerOnly.statusCode, 400);
    expect(
      ((headerOnly.body as Map)['error'] as Map)['code'],
      JsonRpcErrorCode.headerMismatch,
    );

    // Meta-only modern marker (no MCP-Protocol-Version header).
    final metaOnly = await post(
      headers: {
        McpProtocol.methodHeader: 'totally/unknown',
      },
      body: {
        'jsonrpc': '2.0',
        'id': 15,
        'method': 'totally/unknown',
        'params': {
          '_meta': {
            'io.modelcontextprotocol/protocolVersion':
                McpProtocol.currentOfficialVersion,
            'io.modelcontextprotocol/clientInfo': {
              'name': 't',
              'version': '0',
            },
            'io.modelcontextprotocol/clientCapabilities': <String, Object?>{},
          },
        },
      },
    );
    expect(metaOnly.statusCode, 400);
    expect(
      ((metaOnly.body as Map)['error'] as Map)['message'],
      contains('MCP-Protocol-Version'),
    );

    // Matching legacy versions still trip modern marker via _meta presence.
    final legacyVersions = await post(
      headers: {
        McpProtocol.protocolVersionHeader: McpProtocol.specificationVersion,
        McpProtocol.methodHeader: 'totally/unknown',
      },
      body: {
        'jsonrpc': '2.0',
        'id': 11,
        'method': 'totally/unknown',
        'params': {
          '_meta': {
            'io.modelcontextprotocol/protocolVersion':
                McpProtocol.specificationVersion,
            'io.modelcontextprotocol/clientInfo': {
              'name': 't',
              'version': '0',
            },
            'io.modelcontextprotocol/clientCapabilities': <String, Object?>{},
          },
        },
      },
    );
    expect(legacyVersions.statusCode, 400);
    expect(
      ((legacyVersions.body as Map)['error'] as Map)['code'],
      JsonRpcErrorCode.unsupportedProtocolVersion,
    );

    // Header/meta mismatch.
    final mismatch = await post(
      headers: {
        McpProtocol.protocolVersionHeader: McpProtocol.currentOfficialVersion,
        McpProtocol.methodHeader: 'totally/unknown',
      },
      body: {
        'jsonrpc': '2.0',
        'id': 12,
        'method': 'totally/unknown',
        'params': {
          '_meta': {
            'io.modelcontextprotocol/protocolVersion':
                McpProtocol.specificationVersion,
            'io.modelcontextprotocol/clientInfo': {
              'name': 't',
              'version': '0',
            },
            'io.modelcontextprotocol/clientCapabilities': <String, Object?>{},
          },
        },
      },
    );
    expect(mismatch.statusCode, 400);
    expect(
      ((mismatch.body as Map)['error'] as Map)['code'],
      JsonRpcErrorCode.headerMismatch,
    );

    // Missing clientInfo.
    final noClientInfo = await post(
      headers: mcpStreamableHeaders(
        protocolVersion: McpProtocol.currentOfficialVersion,
        method: 'totally/unknown',
      ),
      body: {
        'jsonrpc': '2.0',
        'id': 13,
        'method': 'totally/unknown',
        'params': {
          '_meta': {
            'io.modelcontextprotocol/protocolVersion':
                McpProtocol.currentOfficialVersion,
          },
        },
      },
    );
    expect(noClientInfo.statusCode, 400);
    expect(
      ((noClientInfo.body as Map)['error'] as Map)['message'],
      contains('clientInfo'),
    );

    // Missing clientCapabilities.
    final noCaps = await post(
      headers: mcpStreamableHeaders(
        protocolVersion: McpProtocol.currentOfficialVersion,
        method: 'totally/unknown',
      ),
      body: {
        'jsonrpc': '2.0',
        'id': 16,
        'method': 'totally/unknown',
        'params': {
          '_meta': {
            'io.modelcontextprotocol/protocolVersion':
                McpProtocol.currentOfficialVersion,
            'io.modelcontextprotocol/clientInfo': {
              'name': 't',
              'version': '0',
            },
          },
        },
      },
    );
    expect(noCaps.statusCode, 400);
    expect(
      ((noCaps.body as Map)['error'] as Map)['message'],
      contains('clientCapabilities'),
    );

    // Mcp-Method mismatch.
    final methodMismatch = await post(
      headers: mcpStreamableHeaders(
        protocolVersion: McpProtocol.currentOfficialVersion,
        method: 'tools/list',
      ),
      body: {
        'jsonrpc': '2.0',
        'id': 14,
        'method': 'totally/unknown',
        'params': {
          '_meta': {
            'io.modelcontextprotocol/protocolVersion':
                McpProtocol.currentOfficialVersion,
            'io.modelcontextprotocol/clientInfo': {
              'name': 't',
              'version': '0',
            },
            'io.modelcontextprotocol/clientCapabilities': <String, Object?>{},
          },
        },
      },
    );
    expect(methodMismatch.statusCode, 400);
    expect(
      ((methodMismatch.body as Map)['error'] as Map)['message'],
      contains('Mcp-Method'),
    );
  });

  test('FoundationHandlerTransport legacy unknown → HTTP 200', () async {
    final transport = FoundationHandlerTransport(
      McpFoundationHandler(sessionIdFactory: () => 'sess-legacy-unknown'),
    );
    final init = await transport.post(
      headers: const {},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'initialize',
        'params': {
          'protocolVersion': McpProtocol.specificationVersion,
          'capabilities': <String, Object?>{},
          'clientInfo': {'name': 't', 'version': '1'},
        },
      }),
    );
    expect(init.statusCode, 200);
    final session = init.headers[McpProtocol.sessionIdHeader]!;

    final response = await transport.post(
      headers: {McpProtocol.sessionIdHeader: session},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'id': 2,
        'method': 'totally/unknown',
      }),
    );
    expect(response.statusCode, 200);
    final body = response.body as Map;
    expect((body['error'] as Map)['code'], JsonRpcErrorCode.methodNotFound);
    expect(
      response.headers[McpProtocol.protocolVersionHeader],
      McpProtocol.specificationVersion,
    );
  });

  test('non-2xx transport body with result shape is not success', () async {
    final client = McpSessionClient(
      transport: _HttpErrorWithResultBodyTransport(),
    );
    final init = await client.initialize();
    expect(init.isError, isTrue);
    expect(client.sessionId, isNull);
  });

  test('malformed JSON-RPC error via transport becomes failure not throw',
      () async {
    for (final body in <Map<String, Object?>>[
      {
        'jsonrpc': '2.0',
        'id': 1,
        'error': {'code': '-32603', 'message': 'x'},
      },
      {
        'jsonrpc': '2.0',
        'id': 1,
        'error': {'code': -32603, 'message': 42},
      },
      {
        'jsonrpc': '2.0',
        'id': 1,
        'error': {'message': 'x'},
      },
      {
        'jsonrpc': '2.0',
        'id': 1,
        'error': {'code': -32603},
      },
    ]) {
      final client = McpSessionClient(
        transport: _FixedJsonBodyTransport(body),
      );
      final init = await client.initialize();
      expect(init.isError, isTrue, reason: '$body');
      expect(init.error?.message, contains('invalid JSON-RPC response'));
      expect(client.sessionId, isNull);
    }
  });
}

class _HttpErrorWithResultBodyTransport implements McpStreamableTransport {
  @override
  Future<McpTransportResponse> post({
    required Map<String, String> headers,
    required String body,
  }) async {
    final request = JsonRpcRequest.tryParse(body);
    return McpTransportResponse(
      statusCode: 500,
      headers: {McpProtocol.sessionIdHeader: 'sess-should-not-adopt'},
      body: JsonRpcResponse.result(
        id: request?.id ?? 1,
        result: {
          'protocolVersion': McpProtocol.specificationVersion,
          'capabilities': <String, Object?>{},
          'serverInfo': {'name': 'lie', 'version': '1'},
        },
      ).toJson(),
    );
  }
}

class _FixedJsonBodyTransport implements McpStreamableTransport {
  _FixedJsonBodyTransport(this.body);

  final Map<String, Object?> body;

  @override
  Future<McpTransportResponse> post({
    required Map<String, String> headers,
    required String body,
  }) async {
    return McpTransportResponse(
      statusCode: 200,
      headers: {McpProtocol.sessionIdHeader: 'sess-should-not-adopt'},
      body: this.body,
    );
  }
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
