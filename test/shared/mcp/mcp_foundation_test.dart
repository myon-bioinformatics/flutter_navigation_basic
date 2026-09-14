import 'dart:convert';
import 'dart:math';

import 'package:flutter_application_1/shared/mcp/mcp.dart';
import 'package:flutter_test/flutter_test.dart';

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
  });

  group('Bearer audience inspect', () {
    String demoJwt({required String aud, required int exp}) {
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

    test('rejects tools/list without session and unsupported protocol', () {
      final noSession = handler.handleRpc(
        request: const JsonRpcRequest(id: 1, method: 'tools/list'),
      );
      expect(noSession.response.isError, isTrue);
      expect(
        noSession.response.error!.code,
        JsonRpcErrorCode.sessionRequired,
      );

      final badVersion = handler.handleRpc(
        request: const JsonRpcRequest(
          id: 2,
          method: 'initialize',
          params: {
            'protocolVersion': '1999-01-01',
            'clientInfo': {'name': 'x', 'version': '0'},
          },
        ),
      );
      expect(badVersion.response.isError, isTrue);
    });

    test('resources and prompts require session', () {
      handler.handleRpc(
        request: const JsonRpcRequest(
          id: 1,
          method: 'initialize',
          params: {
            'protocolVersion': McpProtocol.specificationVersion,
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
  });

  test('support matrix exposes pinned version and web OAuth caveat', () {
    expect(
      McpSupportMatrix.asJson['specificationVersion'],
      McpProtocol.specificationVersion,
    );
    expect(McpSupportMatrix.flutterWebInAppOAuthGuaranteed, isFalse);
    expect(McpSupportMatrix.legacySseDefault, isFalse);
  });
}
