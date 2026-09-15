import 'dart:convert';
import 'dart:math';

import 'package:flutter_application_1/shared/mcp/mcp.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../tool/src/mock_mcp.dart';

void main() {
  group('JsonRpcRequest', () {
    test('parses valid request and rejects bad version', () {
      final ok = JsonRpcRequest.tryParse({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'ping',
      });
      expect(ok, isNotNull);
      expect(ok!.method, 'ping');
      expect(ok.isNotification, isFalse);

      expect(
        JsonRpcRequest.tryParse({'jsonrpc': '1.0', 'method': 'ping'}),
        isNull,
      );
    });
  });

  group('PkcePair', () {
    test('generates S256 challenge matching RFC 7636 appendix B', () {
      const verifier = 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk';
      expect(
        PkcePair.codeChallengeS256(verifier),
        'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM',
      );

      final pair = PkcePair.generate(random: Random(42), verifierLength: 64);
      expect(pair.codeVerifier.length, 64);
      expect(pair.codeChallengeMethod, 'S256');
      expect(pair.codeChallenge, PkcePair.codeChallengeS256(pair.codeVerifier));
    });
  });

  group('OAuth metadata', () {
    test('parses authorization server and protected resource documents', () {
      final asMeta = OAuthAuthorizationServerMetadata.fromJson({
        'issuer': 'https://auth.example.test/',
        'authorization_endpoint': 'https://auth.example.test/authorize',
        'token_endpoint': 'https://auth.example.test/token',
        'response_types_supported': ['code'],
        'code_challenge_methods_supported': ['S256'],
        'scopes_supported': ['mcp'],
      });
      expect(asMeta.supportsPkceS256, isTrue);

      final prm = OAuthProtectedResourceMetadata.fromJson({
        'resource': 'https://mcp.example.test/',
        'authorization_servers': ['https://auth.example.test/'],
        'scopes_supported': ['mcp'],
      });
      expect(prm.authorizationServers, hasLength(1));
    });

    test('remote discovery does not invent PKCE or token-auth claims', () {
      final omitted = OAuthAuthorizationServerMetadata.fromJson({
        'issuer': 'https://auth.example.test/',
        'authorization_endpoint': 'https://auth.example.test/authorize',
        'token_endpoint': 'https://auth.example.test/token',
        'response_types_supported': ['code'],
      });
      expect(omitted.codeChallengeMethodsSupported, isEmpty);
      expect(omitted.supportsPkceS256, isFalse);
      expect(
        omitted.tokenEndpointAuthMethodsSupported,
        ['client_secret_basic'],
      );
      expect(
        omitted.grantTypesSupported,
        ['authorization_code', 'implicit'],
      );

      final emptyPkce = OAuthAuthorizationServerMetadata.fromJson({
        'issuer': 'https://auth.example.test/',
        'authorization_endpoint': 'https://auth.example.test/authorize',
        'token_endpoint': 'https://auth.example.test/token',
        'response_types_supported': ['code'],
        'code_challenge_methods_supported': <String>[],
        'token_endpoint_auth_methods_supported': <String>['none'],
      });
      expect(emptyPkce.supportsPkceS256, isFalse);
      expect(emptyPkce.tokenEndpointAuthMethodsSupported, ['none']);
    });

    test('requires response_types_supported; rejects wrong-type arrays', () {
      expect(
        () => OAuthAuthorizationServerMetadata.fromJson({
          'issuer': 'https://auth.example.test/',
          'authorization_endpoint': 'https://auth.example.test/authorize',
          'token_endpoint': 'https://auth.example.test/token',
        }),
        throwsFormatException,
      );
      expect(
        () => OAuthAuthorizationServerMetadata.fromJson({
          'issuer': 'https://auth.example.test/',
          'authorization_endpoint': 'https://auth.example.test/authorize',
          'token_endpoint': 'https://auth.example.test/token',
          'response_types_supported': <String>[],
        }),
        throwsFormatException,
      );
      expect(
        () => OAuthAuthorizationServerMetadata.fromJson({
          'issuer': 'https://auth.example.test/',
          'authorization_endpoint': 'https://auth.example.test/authorize',
          'token_endpoint': 'https://auth.example.test/token',
          'response_types_supported': 'code',
        }),
        throwsFormatException,
      );
      expect(
        () => OAuthAuthorizationServerMetadata.fromJson({
          'issuer': 'https://auth.example.test/',
          'authorization_endpoint': 'https://auth.example.test/authorize',
          'token_endpoint': 'https://auth.example.test/token',
          'response_types_supported': ['code', 1],
        }),
        throwsFormatException,
      );
    });
  });

  group('Bearer audience inspect', () {
    String demoJwt({required Object aud, required int exp}) {
      String b64(Map<String, Object?> map) =>
          base64Url.encode(utf8.encode(jsonEncode(map))).replaceAll('=', '');
      return '${b64({'alg': 'none', 'typ': 'JWT'})}.'
          '${b64({'aud': aud, 'exp': exp})}.'
          'sig';
    }

    test('missing / expired / wrong audience / ok', () {
      final now = DateTime.utc(2026, 9, 14, 12);
      expect(
        inspectBearerAudience(
          null,
          expectedAudience: 'https://mcp.example.test',
        ).status,
        BearerAudienceStatus.missing,
      );
      expect(
        inspectBearerAudience(
          'Bearer ${demoJwt(aud: 'https://mcp.example.test', exp: 1)}',
          expectedAudience: 'https://mcp.example.test',
          clock: () => now,
        ).status,
        BearerAudienceStatus.expired,
      );
      expect(
        inspectBearerAudience(
          'Bearer ${demoJwt(aud: 'https://other.test', exp: 9999999999)}',
          expectedAudience: 'https://mcp.example.test',
          clock: () => now,
        ).status,
        BearerAudienceStatus.wrongAudience,
      );
      expect(
        inspectBearerAudience(
          'Bearer ${demoJwt(aud: 'https://mcp.example.test', exp: 9999999999)}',
          expectedAudience: 'https://mcp.example.test',
          clock: () => now,
        ).status,
        BearerAudienceStatus.ok,
      );
    });

    test('audience arrays: match any entry; reject malformed members', () {
      final now = DateTime.utc(2026, 9, 14, 12);
      expect(
        inspectBearerAudience(
          'Bearer ${demoJwt(aud: [
                'https://a.test',
                'https://mcp.example.test',
              ], exp: 9999999999)}',
          expectedAudience: 'https://mcp.example.test',
          clock: () => now,
        ).status,
        BearerAudienceStatus.ok,
      );
      expect(
        inspectBearerAudience(
          'Bearer ${demoJwt(aud: [
                'https://a.test',
                'https://b.test',
              ], exp: 9999999999)}',
          expectedAudience: 'https://mcp.example.test',
          clock: () => now,
        ).status,
        BearerAudienceStatus.wrongAudience,
      );
      expect(
        inspectBearerAudience(
          'Bearer ${demoJwt(aud: [
                'https://a.test',
                42,
              ], exp: 9999999999)}',
          expectedAudience: 'https://mcp.example.test',
          clock: () => now,
        ).status,
        BearerAudienceStatus.malformed,
      );
    });
  });

  group('McpFoundationHandler', () {
    late McpFoundationHandler handler;

    setUp(() {
      handler = McpFoundationHandler(sessionIdFactory: () => 'sess-1');
    });

    test('initialize → tools/list → tools/call session flow', () {
      final init = handler.handleRpc(
        request: const JsonRpcRequest(
          id: 1,
          method: 'initialize',
          params: {
            'protocolVersion': McpProtocol.specificationVersion,
            'capabilities': <String, Object?>{},
            'clientInfo': {'name': 'test', 'version': '0'},
          },
        ),
      );
      expect(init.response.isError, isFalse);
      expect(init.sessionId, 'sess-1');
      expect(
        (init.response.result as Map)['protocolVersion'],
        McpProtocol.specificationVersion,
      );

      final listed = handler.handleRpc(
        request: const JsonRpcRequest(id: 2, method: 'tools/list'),
        sessionId: 'sess-1',
      );
      expect(listed.response.isError, isFalse);
      expect((listed.response.result as Map)['tools'], isNotEmpty);

      final called = handler.handleRpc(
        request: const JsonRpcRequest(
          id: 3,
          method: 'tools/call',
          params: {
            'name': 'echo',
            'arguments': {'text': 'hi'},
          },
        ),
        sessionId: 'sess-1',
      );
      expect(called.response.isError, isFalse);
      final content = (called.response.result as Map)['content'] as List;
      expect((content.first as Map)['text'], 'hi');
    });

    test('negotiate unsupported client version by returning pinned success', () {
      final negotiated = handler.handleRpc(
        request: const JsonRpcRequest(
          id: 1,
          method: 'initialize',
          params: {
            'protocolVersion': '1999-01-01',
            'capabilities': <String, Object?>{},
            'clientInfo': {'name': 'x', 'version': '0'},
          },
        ),
      );
      expect(negotiated.response.isError, isFalse);
      expect(negotiated.sessionId, 'sess-1');
      expect(
        (negotiated.response.result as Map)['protocolVersion'],
        McpProtocol.specificationVersion,
      );
    });

    test('rejects missing/malformed initialize required fields', () {
      for (final params in <Map<String, Object?>>[
        {
          'capabilities': <String, Object?>{},
          'clientInfo': {'name': 'x', 'version': '0'},
        },
        {
          'protocolVersion': 20250326,
          'capabilities': <String, Object?>{},
          'clientInfo': {'name': 'x', 'version': '0'},
        },
        {
          'protocolVersion': McpProtocol.specificationVersion,
          'clientInfo': {'name': 'x', 'version': '0'},
        },
        {
          'protocolVersion': McpProtocol.specificationVersion,
          'capabilities': 'nope',
          'clientInfo': {'name': 'x', 'version': '0'},
        },
        {
          'protocolVersion': McpProtocol.specificationVersion,
          'capabilities': <String, Object?>{},
        },
        {
          'protocolVersion': McpProtocol.specificationVersion,
          'capabilities': <String, Object?>{},
          'clientInfo': 'nope',
        },
        {
          'protocolVersion': McpProtocol.specificationVersion,
          'capabilities': <String, Object?>{},
          'clientInfo': <String, Object?>{},
        },
        {
          'protocolVersion': McpProtocol.specificationVersion,
          'capabilities': <String, Object?>{},
          'clientInfo': {'version': '0'},
        },
        {
          'protocolVersion': McpProtocol.specificationVersion,
          'capabilities': <String, Object?>{},
          'clientInfo': {'name': 'x'},
        },
        {
          'protocolVersion': McpProtocol.specificationVersion,
          'capabilities': <String, Object?>{},
          'clientInfo': {'name': '', 'version': '0'},
        },
        {
          'protocolVersion': McpProtocol.specificationVersion,
          'capabilities': <String, Object?>{},
          'clientInfo': {'name': 'x', 'version': ''},
        },
        {
          'protocolVersion': McpProtocol.specificationVersion,
          'capabilities': <String, Object?>{},
          'clientInfo': {'name': 1, 'version': '0'},
        },
        {
          'protocolVersion': McpProtocol.specificationVersion,
          'capabilities': <String, Object?>{},
          'clientInfo': {'name': 'x', 'version': 2},
        },
      ]) {
        final bad = handler.handleRpc(
          request: JsonRpcRequest(
            id: 1,
            method: 'initialize',
            params: params,
          ),
        );
        expect(bad.response.isError, isTrue);
        expect(bad.response.error!.code, JsonRpcErrorCode.invalidParams);
        expect(bad.sessionId, isNull);
        expect(handler.session('sess-1'), isNull);
      }
    });

    test('rejects tools/list and initialized without session', () {
      final noSession = handler.handleRpc(
        request: const JsonRpcRequest(id: 1, method: 'tools/list'),
      );
      expect(noSession.response.isError, isTrue);
      expect(
        noSession.response.error!.code,
        JsonRpcErrorCode.sessionRequired,
      );

      final initialized = handler.handleRpc(
        request: const JsonRpcRequest(
          method: 'notifications/initialized',
        ),
      );
      expect(initialized.response.isError, isTrue);
      expect(
        initialized.response.error!.code,
        JsonRpcErrorCode.sessionRequired,
      );
    });

    test('resources and prompts require session', () {
      handler.handleRpc(
        request: const JsonRpcRequest(
          id: 1,
          method: 'initialize',
          params: {
            'protocolVersion': McpProtocol.specificationVersion,
            'capabilities': <String, Object?>{},
            'clientInfo': {'name': 't', 'version': '0'},
          },
        ),
      );
      final resources = handler.handleRpc(
        request: const JsonRpcRequest(id: 2, method: 'resources/list'),
        sessionId: 'sess-1',
      );
      expect(resources.response.isError, isFalse);
      final prompts = handler.handleRpc(
        request: const JsonRpcRequest(
          id: 3,
          method: 'prompts/get',
          params: {'name': 'greet'},
        ),
        sessionId: 'sess-1',
      );
      expect(prompts.response.isError, isFalse);
    });

    test('default session ids are high-entropy and non-repeating', () {
      final ids = List<String>.generate(
        20,
        (_) => generateMcpSessionId(),
      );
      expect(ids.toSet(), hasLength(20));
      for (final id in ids) {
        expect(id, isNot(contains('=')));
        expect(id.length, greaterThanOrEqualTo(20));
        expect(RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(id), isTrue);
      }
    });
  });

  group('MockMcpRoutes HTTP session / Origin contract', () {
    late MockMcpRoutes routes;

    setUp(() {
      routes = MockMcpRoutes(
        handler: McpFoundationHandler(sessionIdFactory: () => 'sess-http'),
      );
    });

    Map<String, Object?> initBody() => {
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'initialize',
          'params': {
            'protocolVersion': McpProtocol.specificationVersion,
            'capabilities': <String, Object?>{},
            'clientInfo': {'name': 't', 'version': '0'},
          },
        };

    test('initialized without session → 400; unknown session → 404', () {
      final missing = routes.handle(
        method: 'POST',
        path: '/mcp',
        headers: const {},
        rawBody: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'notifications/initialized',
        }),
      )!;
      expect(missing.statusCode, 400);
      expect((missing.body as Map)['error'], 'session_required');

      final unknown = routes.handle(
        method: 'POST',
        path: '/mcp',
        headers: {McpProtocol.sessionIdHeader: 'nope'},
        rawBody: jsonEncode({
          'jsonrpc': '2.0',
          'id': 2,
          'method': 'tools/list',
        }),
      )!;
      expect(unknown.statusCode, 404);
      expect((unknown.body as Map)['error'], 'session_not_found');
    });

    test('allowed / rejected / absent Origin', () {
      final init = routes.handle(
        method: 'POST',
        path: '/mcp',
        headers: const {},
        rawBody: jsonEncode(initBody()),
      )!;
      expect(init.statusCode, 200);
      final session = init.headers[McpProtocol.sessionIdHeader]!;

      final allowed = routes.handle(
        method: 'POST',
        path: '/mcp',
        headers: {
          McpProtocol.sessionIdHeader: session,
          'origin': 'http://127.0.0.1:8787',
        },
        rawBody: jsonEncode({
          'jsonrpc': '2.0',
          'id': 2,
          'method': 'tools/list',
        }),
      )!;
      expect(allowed.statusCode, 200);

      final rejected = routes.handle(
        method: 'POST',
        path: '/mcp',
        headers: {
          McpProtocol.sessionIdHeader: session,
          'origin': 'https://evil.example',
        },
        rawBody: jsonEncode({
          'jsonrpc': '2.0',
          'id': 3,
          'method': 'tools/list',
        }),
      )!;
      expect(rejected.statusCode, 403);
      expect((rejected.body as Map)['error'], 'origin_forbidden');

      final absent = routes.handle(
        method: 'POST',
        path: '/mcp',
        headers: {McpProtocol.sessionIdHeader: session},
        rawBody: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'notifications/initialized',
        }),
      )!;
      expect(absent.statusCode, 202);
    });
  });

  group('MockMcpRoutes auth + discovery port', () {
    test('initialized with invalid/expired/wrong-audience Bearer → 401/403', () {
      final routes = MockMcpRoutes(
        handler: McpFoundationHandler(sessionIdFactory: () => 'sess-auth'),
        expectedAudience: 'http://127.0.0.1:8787/mcp',
      );
      final init = routes.handle(
        method: 'POST',
        path: '/mcp',
        headers: const {},
        rawBody: jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'initialize',
          'params': {
            'protocolVersion': McpProtocol.specificationVersion,
            'capabilities': <String, Object?>{},
            'clientInfo': {'name': 't', 'version': '0'},
          },
        }),
      )!;
      expect(init.statusCode, 200);
      final session = init.headers[McpProtocol.sessionIdHeader]!;

      final expired = routes.handle(
        method: 'POST',
        path: '/mcp',
        headers: {
          McpProtocol.sessionIdHeader: session,
          'authorization':
              'Bearer ${demoBearerToken(audience: 'http://127.0.0.1:8787/mcp', expiresAt: DateTime.utc(2020))}',
        },
        rawBody: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'notifications/initialized',
        }),
      )!;
      expect(expired.statusCode, 401);

      final wrongAud = routes.handle(
        method: 'POST',
        path: '/mcp',
        headers: {
          McpProtocol.sessionIdHeader: session,
          'authorization':
              'Bearer ${demoBearerToken(audience: 'http://evil.example/mcp', expiresAt: DateTime.utc(2099))}',
        },
        rawBody: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'notifications/initialized',
        }),
      )!;
      expect(wrongAud.statusCode, 403);

      final malformed = routes.handle(
        method: 'POST',
        path: '/mcp',
        headers: {
          McpProtocol.sessionIdHeader: session,
          'authorization': 'Bearer not-a-jwt',
        },
        rawBody: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'notifications/initialized',
        }),
      )!;
      expect(malformed.statusCode, 401);
    });

    test('forPort discovery URLs follow non-default listen port', () {
      final routes = MockMcpRoutes.forPort(9999);
      expect(routes.issuer, 'http://127.0.0.1:9999');
      expect(routes.resource, 'http://127.0.0.1:9999/mcp');
      expect(routes.expectedAudience, 'http://127.0.0.1:9999/mcp');
      expect(
        routes.originPolicy.allows('http://127.0.0.1:9999'),
        isTrue,
      );
      expect(
        routes.originPolicy.allows('http://127.0.0.1:8787'),
        isFalse,
      );

      final asDoc = routes.handle(
        method: 'GET',
        path: '/.well-known/oauth-authorization-server',
        headers: const {},
        rawBody: null,
      )!;
      expect(asDoc.statusCode, 200);
      final asBody = asDoc.body as Map;
      expect(asBody['issuer'], 'http://127.0.0.1:9999');
      expect(
        asBody['authorization_endpoint'],
        'http://127.0.0.1:9999/oauth/authorize',
      );
      expect(asBody['token_endpoint'], 'http://127.0.0.1:9999/oauth/token');

      final prm = routes.handle(
        method: 'GET',
        path: '/.well-known/oauth-protected-resource',
        headers: const {},
        rawBody: null,
      )!;
      expect((prm.body as Map)['resource'], 'http://127.0.0.1:9999/mcp');
      expect(
        (prm.body as Map)['authorization_servers'],
        ['http://127.0.0.1:9999'],
      );
    });
  });


  group('OAuth metadata typing (post-merge #69 Copilot nits)', () {
    test('registration_endpoint wrong type / empty → FormatException', () {
      expect(
        () => OAuthAuthorizationServerMetadata.fromJson({
          'issuer': 'https://auth.example.test/',
          'authorization_endpoint': 'https://auth.example.test/authorize',
          'token_endpoint': 'https://auth.example.test/token',
          'response_types_supported': ['code'],
          'registration_endpoint': 123,
        }),
        throwsFormatException,
      );
      expect(
        () => OAuthAuthorizationServerMetadata.fromJson({
          'issuer': 'https://auth.example.test/',
          'authorization_endpoint': 'https://auth.example.test/authorize',
          'token_endpoint': 'https://auth.example.test/token',
          'response_types_supported': ['code'],
          'registration_endpoint': '',
        }),
        throwsFormatException,
      );
    });

    test('authorization_servers rejects non-string / empty members', () {
      expect(
        () => OAuthProtectedResourceMetadata.fromJson({
          'resource': 'https://mcp.example.test/',
          'authorization_servers': ['https://auth.example.test/', 1],
        }),
        throwsFormatException,
      );
      expect(
        () => OAuthProtectedResourceMetadata.fromJson({
          'resource': 'https://mcp.example.test/',
          'authorization_servers': [''],
        }),
        throwsFormatException,
      );
      expect(
        () => OAuthProtectedResourceMetadata.fromJson({
          'resource': 'https://mcp.example.test/',
          'authorization_servers': ['https://auth.example.test/'],
          'resource_name': 9,
        }),
        throwsFormatException,
      );
    });
  });

  test('support matrix exposes pinned version and web OAuth caveat', () {
    expect(
      McpSupportMatrix.asJson['specificationVersion'],
      McpProtocol.specificationVersion,
    );
    expect(McpSupportMatrix.flutterWebInAppOAuthGuaranteed, isFalse);
    expect(McpSupportMatrix.legacySseDefault, isFalse);
    expect(McpSupportMatrix.legacyMcpEra, isTrue);
    expect(McpSupportMatrix.currentOfficialEra, isTrue);
    expect(
      McpSupportMatrix.currentOfficialVersion,
      McpProtocol.currentOfficialVersion,
    );
    expect(McpSupportMatrix.implementsCurrentOfficial, isTrue);
  });
}
