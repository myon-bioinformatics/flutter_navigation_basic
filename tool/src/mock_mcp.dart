import 'dart:convert';

import 'package:flutter_application_1/shared/mcp/mcp.dart';

/// Local Streamable HTTP Origin policy for the mock MCP route.
///
/// Absent Origin remains allowed (CLI/curl). Present Origin must match the
/// allowlist or the request is rejected with HTTP 403 (DNS-rebinding guard).
class McpOriginPolicy {
  const McpOriginPolicy({
    this.allowedOrigins = const {
      'http://127.0.0.1:8787',
      'http://localhost:8787',
    },
  });

  final Set<String> allowedOrigins;

  /// Returns false when a present Origin is not allowlisted.
  bool allows(String? origin) {
    if (origin == null || origin.isEmpty) return true;
    return allowedOrigins.contains(origin);
  }

  /// Builds an allowlist for a loopback mock listening on [port].
  factory McpOriginPolicy.forPort(int port) {
    return McpOriginPolicy(
      allowedOrigins: {
        'http://127.0.0.1:$port',
        'http://localhost:$port',
      },
    );
  }
}

/// Demo OAuth discovery + MCP Streamable HTTP JSON-RPC routes for the mock server.
class MockMcpRoutes {
  MockMcpRoutes({
    McpFoundationHandler? handler,
    this.resource = 'http://127.0.0.1:8787/mcp',
    this.issuer = 'http://127.0.0.1:8787',
    this.expectedAudience = 'http://127.0.0.1:8787/mcp',
    this.originPolicy = const McpOriginPolicy(),
  }) : handler = handler ?? McpFoundationHandler();

  /// Builds discovery URLs / audience / Origin policy from the effective listen
  /// [port] so `--port` cannot drift from published metadata.
  factory MockMcpRoutes.forPort(
    int port, {
    McpFoundationHandler? handler,
  }) {
    final base = 'http://127.0.0.1:$port';
    return MockMcpRoutes(
      handler: handler,
      resource: '$base/mcp',
      issuer: base,
      expectedAudience: '$base/mcp',
      originPolicy: McpOriginPolicy.forPort(port),
    );
  }

  final McpFoundationHandler handler;
  final String resource;
  final String issuer;
  final String expectedAudience;
  final McpOriginPolicy originPolicy;

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
      // Local fixture intentionally advertises S256; remote discovery parsing
      // must not invent that claim when the field is absent.
      final meta = OAuthAuthorizationServerMetadata(
        issuer: issuer,
        authorizationEndpoint: '$issuer/oauth/authorize',
        tokenEndpoint: '$issuer/oauth/token',
        scopesSupported: const ['mcp'],
        responseTypesSupported: const ['code'],
        grantTypesSupported: const ['authorization_code'],
        codeChallengeMethodsSupported: const ['S256'],
        tokenEndpointAuthMethodsSupported: const ['none', 'client_secret_basic'],
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
    String? headerValue(String name) {
      final wanted = name.toLowerCase();
      for (final entry in headers.entries) {
        if (entry.key.toLowerCase() == wanted) return entry.value;
      }
      return null;
    }

    final origin = headerValue('origin');
    if (!originPolicy.allows(origin)) {
      return (
        statusCode: 403,
        headers: const {},
        body: {
          'error': 'origin_forbidden',
          'origin': origin,
        },
      );
    }

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

    final inboundSession = headerValue(McpProtocol.sessionIdHeader);
    final isInitialize = request.method == 'initialize';
    final headerProtocol = headerValue(McpProtocol.protocolVersionHeader);
    final metaVersion = _mcpMetaProtocolVersion(request);
    final looksModern = request.method == 'server/discover' ||
        metaVersion != null ||
        headerProtocol == McpProtocol.currentOfficialVersion;

    if (looksModern) {
      final modernError = _validateModernMcpHttp(
        request: request,
        headerProtocol: headerProtocol,
        metaVersion: metaVersion,
        headerMethod: headerValue(McpProtocol.methodHeader),
        headerName: headerValue(McpProtocol.nameHeader),
      );
      if (modernError != null) {
        return (
          statusCode: 400,
          headers: {
            McpProtocol.protocolVersionHeader:
                McpProtocol.currentOfficialVersion,
          },
          body: modernError.toJson(),
        );
      }
    } else if (!isInitialize) {
      // Legacy Streamable HTTP: every post-initialize request/notification
      // must carry the issued session id.
      if (inboundSession == null || inboundSession.isEmpty) {
        return (
          statusCode: 400,
          headers: const {},
          body: {
            'error': 'session_required',
            'message': 'Mcp-Session-Id required after initialize',
          },
        );
      }
      if (handler.session(inboundSession) == null) {
        return (
          statusCode: 404,
          headers: const {},
          body: {
            'error': 'session_not_found',
            'message': 'unknown Mcp-Session-Id',
          },
        );
      }
    }

    final outcome = handler.handleRpc(
      request: request,
      sessionId: looksModern ? null : inboundSession,
      bearer: gate,
    );

    final outHeaders = <String, String>{
      if (outcome.sessionId != null)
        McpProtocol.sessionIdHeader: outcome.sessionId!,
      McpProtocol.protocolVersionHeader: looksModern
          ? McpProtocol.currentOfficialVersion
          : McpProtocol.specificationVersion,
    };

    final code = outcome.response.error?.code;
    if (code == JsonRpcErrorCode.unauthorized) {
      return (
        statusCode: 401,
        headers: outHeaders,
        body: {
          'error': 'unauthorized',
          'message': outcome.response.error?.message,
          'reason': outcome.response.error?.data,
        },
      );
    }
    if (code == JsonRpcErrorCode.forbidden) {
      return (
        statusCode: 403,
        headers: outHeaders,
        body: {
          'error': 'forbidden',
          'message': outcome.response.error?.message,
          'reason': outcome.response.error?.data,
        },
      );
    }

    // Accepted notifications: HTTP 202 with empty body (no JSON-RPC response).
    // Rejected notifications: HTTP error — do not pretend success.
    if (request.isNotification) {
      if (outcome.response.isError) {
        return (
          statusCode: 400,
          headers: outHeaders,
          body: {
            'error': 'notification_rejected',
            'message': outcome.response.error?.message,
            'code': outcome.response.error?.code,
          },
        );
      }
      return (statusCode: 202, headers: outHeaders, body: null);
    }

    // Current-official Streamable HTTP: unimplemented RPC → HTTP 404.
    if (looksModern && code == JsonRpcErrorCode.methodNotFound) {
      return (
        statusCode: 404,
        headers: outHeaders,
        body: outcome.response.toJson(),
      );
    }

    return (
      statusCode: 200,
      headers: outHeaders,
      body: outcome.response.toJson(),
    );
  }
}


String? _mcpMetaProtocolVersion(JsonRpcRequest request) {
  final params = request.params;
  if (params is! Map) return null;
  final meta = params['_meta'];
  if (meta is! Map) return null;
  final version = meta['io.modelcontextprotocol/protocolVersion'];
  return version is String ? version : null;
}

/// Validates current-official Streamable HTTP headers against body `_meta`.
JsonRpcResponse? _validateModernMcpHttp({
  required JsonRpcRequest request,
  required String? headerProtocol,
  required String? metaVersion,
  required String? headerMethod,
  required String? headerName,
}) {
  if (headerProtocol == null || headerProtocol.isEmpty) {
    return JsonRpcResponse.failure(
      id: request.id,
      error: const JsonRpcError(
        code: JsonRpcErrorCode.headerMismatch,
        message: 'MCP-Protocol-Version header is required',
      ),
    );
  }
  final params = request.params is Map
      ? Map<String, Object?>.from(request.params as Map)
      : null;
  final meta = params == null
      ? null
      : (params['_meta'] is Map
          ? Map<String, Object?>.from(params['_meta'] as Map)
          : null);
  if (meta == null) {
    return JsonRpcResponse.failure(
      id: request.id,
      error: const JsonRpcError(
        code: JsonRpcErrorCode.headerMismatch,
        message: 'params._meta is required',
      ),
    );
  }
  if (metaVersion == null || metaVersion.isEmpty) {
    return JsonRpcResponse.failure(
      id: request.id,
      error: const JsonRpcError(
        code: JsonRpcErrorCode.headerMismatch,
        message: 'params._meta protocolVersion is required',
      ),
    );
  }
  if (headerProtocol != metaVersion) {
    return JsonRpcResponse.failure(
      id: request.id,
      error: JsonRpcError(
        code: JsonRpcErrorCode.headerMismatch,
        message: 'MCP-Protocol-Version does not match body _meta',
        data: {
          'header': headerProtocol,
          'meta': metaVersion,
        },
      ),
    );
  }
  if (headerProtocol != McpProtocol.currentOfficialVersion) {
    return JsonRpcResponse.failure(
      id: request.id,
      error: JsonRpcError(
        code: JsonRpcErrorCode.unsupportedProtocolVersion,
        message: 'Unsupported protocol version',
        data: {
          'supported': [
            McpProtocol.specificationVersion,
            McpProtocol.currentOfficialVersion,
          ],
          'requested': headerProtocol,
        },
      ),
    );
  }

  final clientInfo = meta['io.modelcontextprotocol/clientInfo'];
  if (clientInfo is! Map) {
    return JsonRpcResponse.failure(
      id: request.id,
      error: const JsonRpcError(
        code: JsonRpcErrorCode.headerMismatch,
        message: 'params._meta clientInfo must be an object',
      ),
    );
  }
  final clientInfoMap = Map<String, Object?>.from(clientInfo);
  final clientName = clientInfoMap['name'];
  final clientVersion = clientInfoMap['version'];
  if (clientName is! String || clientName.isEmpty) {
    return JsonRpcResponse.failure(
      id: request.id,
      error: const JsonRpcError(
        code: JsonRpcErrorCode.headerMismatch,
        message: 'params._meta clientInfo.name must be a non-empty string',
      ),
    );
  }
  if (clientVersion is! String || clientVersion.isEmpty) {
    return JsonRpcResponse.failure(
      id: request.id,
      error: const JsonRpcError(
        code: JsonRpcErrorCode.headerMismatch,
        message: 'params._meta clientInfo.version must be a non-empty string',
      ),
    );
  }
  final clientCapabilities = meta['io.modelcontextprotocol/clientCapabilities'];
  if (clientCapabilities is! Map) {
    return JsonRpcResponse.failure(
      id: request.id,
      error: const JsonRpcError(
        code: JsonRpcErrorCode.headerMismatch,
        message: 'params._meta clientCapabilities must be an object',
      ),
    );
  }

  if (headerMethod == null || headerMethod.isEmpty) {
    return JsonRpcResponse.failure(
      id: request.id,
      error: const JsonRpcError(
        code: JsonRpcErrorCode.headerMismatch,
        message: 'Mcp-Method header is required',
      ),
    );
  }
  if (headerMethod != request.method) {
    return JsonRpcResponse.failure(
      id: request.id,
      error: JsonRpcError(
        code: JsonRpcErrorCode.headerMismatch,
        message: 'Mcp-Method does not match JSON-RPC method',
        data: {
          'header': headerMethod,
          'method': request.method,
        },
      ),
    );
  }

  final needsName = request.method == 'tools/call' ||
      request.method == 'resources/read' ||
      request.method == 'prompts/get';
  if (needsName) {
    final Object? expected = request.method == 'resources/read'
        ? (params == null ? null : params['uri'])
        : (params == null ? null : params['name']);
    if (headerName == null || headerName.isEmpty) {
      return JsonRpcResponse.failure(
        id: request.id,
        error: const JsonRpcError(
          code: JsonRpcErrorCode.headerMismatch,
          message: 'Mcp-Name header is required',
        ),
      );
    }
    final decodedName = McpHeaderCodec.decode(headerName);
    if (decodedName == null) {
      return JsonRpcResponse.failure(
        id: request.id,
        error: const JsonRpcError(
          code: JsonRpcErrorCode.headerMismatch,
          message: 'Mcp-Name header is malformed',
        ),
      );
    }
    if (expected is String && decodedName != expected) {
      return JsonRpcResponse.failure(
        id: request.id,
        error: JsonRpcError(
          code: JsonRpcErrorCode.headerMismatch,
          message: 'Mcp-Name does not match body params',
          data: {
            'header': headerName,
            'decoded': decodedName,
            'expected': expected,
          },
        ),
      );
    }
  }
  return null;
}

/// Demo unsigned JWT-shaped bearer for local audience tests.
String demoBearerToken({
  required Object audience,
  required DateTime expiresAt,
}) {
  String b64(Map<String, Object?> map) =>
      base64Url.encode(utf8.encode(jsonEncode(map))).replaceAll('=', '');
  final exp = expiresAt.toUtc().millisecondsSinceEpoch ~/ 1000;
  return '${b64({'alg': 'none', 'typ': 'JWT'})}.'
      '${b64({'aud': audience, 'exp': exp})}.'
      'demo-sig';
}
