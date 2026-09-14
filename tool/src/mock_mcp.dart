import 'dart:convert';

import 'package:flutter_application_1/shared/mcp/mcp.dart';

/// Demo OAuth discovery + MCP Streamable HTTP JSON-RPC routes for the mock server.
class MockMcpRoutes {
  MockMcpRoutes({
    McpFoundationHandler? handler,
    this.resource = 'http://127.0.0.1/mcp',
    this.issuer = 'http://127.0.0.1',
    this.expectedAudience = 'http://127.0.0.1/mcp',
  }) : handler = handler ?? McpFoundationHandler();

  final McpFoundationHandler handler;
  final String resource;
  final String issuer;
  final String expectedAudience;

  /// Returns status/headers/body when [path] is an MCP/OAuth demo route.
  ({int statusCode, Map<String, String> headers, Object? body})? handle({
    required String method,
    required String path,
    required Map<String, String> headers,
    required String? rawBody,
  }) {
    final normalized =
        path.endsWith('/') && path.length > 1 ? path.substring(0, path.length - 1) : path;

    if (normalized == '/.well-known/oauth-authorization-server') {
      final meta = OAuthAuthorizationServerMetadata(
        issuer: issuer,
        authorizationEndpoint: '$issuer/oauth/authorize',
        tokenEndpoint: '$issuer/oauth/token',
        scopesSupported: const ['mcp'],
        codeChallengeMethodsSupported: const ['S256'],
      );
      return (statusCode: 200, headers: const {}, body: meta.toJson());
    }

    if (normalized == '/.well-known/oauth-protected-resource' ||
        normalized == '/.well-known/oauth-protected-resource/mcp') {
      final meta = OAuthProtectedResourceMetadata(
        resource: resource,
        authorizationServers: [issuer],
        scopesSupported: const ['mcp'],
      );
      return (statusCode: 200, headers: const {}, body: meta.toJson());
    }

    if (normalized == '/mcp/support-matrix') {
      return (statusCode: 200, headers: const {}, body: McpSupportMatrix.asJson);
    }

    if (normalized == '/mcp') {
      if (method.toUpperCase() != 'POST') {
        return (
          statusCode: 405,
          headers: const {'allow': 'POST'},
          body: {'error': 'method_not_allowed'},
        );
      }
      return _handleMcpPost(headers: headers, rawBody: rawBody);
    }

    return null;
  }

  ({int statusCode, Map<String, String> headers, Object? body}) _handleMcpPost({
    required Map<String, String> headers,
    required String? rawBody,
  }) {
    final request = JsonRpcRequest.tryParse(rawBody);
    if (request == null) {
      return (
        statusCode: 400,
        headers: const {},
        body: JsonRpcResponse.failure(
          id: null,
          error: const JsonRpcError(
            code: JsonRpcErrorCode.parseError,
            message: 'parse error',
          ),
        ).toJson(),
      );
    }

    String? headerValue(String name) {
      final wanted = name.toLowerCase();
      for (final entry in headers.entries) {
        if (entry.key.toLowerCase() == wanted) return entry.value;
      }
      return null;
    }

    final auth = headerValue('authorization');
    BearerGate? gate;
    if (auth != null && auth.isNotEmpty) {
      final claim = inspectBearerAudience(
        auth,
        expectedAudience: expectedAudience,
      );
      gate = switch (claim.status) {
        BearerAudienceStatus.ok => BearerGate.ok,
        BearerAudienceStatus.wrongAudience => const BearerGate(
            status: BearerGateStatus.forbidden,
            reason: 'wrong_audience',
          ),
        BearerAudienceStatus.expired => const BearerGate(
            status: BearerGateStatus.unauthorized,
            reason: 'expired',
          ),
        BearerAudienceStatus.missing || BearerAudienceStatus.malformed =>
          const BearerGate(
            status: BearerGateStatus.unauthorized,
            reason: 'invalid_bearer',
          ),
      };
    }

    final outcome = handler.handleRpc(
      request: request,
      sessionId: headerValue(McpProtocol.sessionIdHeader),
      bearer: gate,
    );

    final outHeaders = <String, String>{
      if (outcome.sessionId != null)
        McpProtocol.sessionIdHeader: outcome.sessionId!,
      McpProtocol.protocolVersionHeader: McpProtocol.specificationVersion,
    };

    if (request.isNotification &&
        request.method == 'notifications/initialized') {
      return (statusCode: 202, headers: outHeaders, body: null);
    }

    final code = outcome.response.error?.code;
    final status = switch (code) {
      JsonRpcErrorCode.unauthorized => 401,
      JsonRpcErrorCode.forbidden => 403,
      _ => 200,
    };

    return (
      statusCode: status,
      headers: outHeaders,
      body: outcome.response.toJson(),
    );
  }
}

/// Demo unsigned JWT-shaped bearer for local audience tests.
String demoBearerToken({
  required String audience,
  required DateTime expiresAt,
}) {
  String b64(Map<String, Object?> map) =>
      base64Url.encode(utf8.encode(jsonEncode(map))).replaceAll('=', '');
  final exp = expiresAt.toUtc().millisecondsSinceEpoch ~/ 1000;
  return '${b64({'alg': 'none', 'typ': 'JWT'})}.'
      '${b64({'aud': audience, 'exp': exp})}.'
      'demo-sig';
}
