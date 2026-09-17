import 'dart:convert';

import 'json_rpc.dart';
import 'mcp_foundation.dart';
import 'mcp_modern_http.dart';
import 'mcp_protocol.dart';

/// Transport for one Streamable HTTP MCP POST.
abstract class McpStreamableTransport {
  Future<McpTransportResponse> post({
    required Map<String, String> headers,
    required String body,
  });
}

class McpTransportResponse {
  const McpTransportResponse({
    required this.statusCode,
    required this.headers,
    this.body,
  });

  final int statusCode;
  final Map<String, String> headers;
  final Object? body;
}

/// In-process transport over a [MockMcpRoutes]-compatible handler callback.
///
/// Used by widget/unit tests and the MCP integration screen so demos work
/// without a live mock server process.
class InProcessMcpTransport implements McpStreamableTransport {
  InProcessMcpTransport({
    required this.dispatch,
    this.path = '/mcp',
  });

  final ({int statusCode, Map<String, String> headers, Object? body})? Function({
    required String method,
    required String path,
    required Map<String, String> headers,
    required String? rawBody,
  }) dispatch;

  final String path;

  @override
  Future<McpTransportResponse> post({
    required Map<String, String> headers,
    required String body,
  }) async {
    final outcome = dispatch(
      method: 'POST',
      path: path,
      headers: headers,
      rawBody: body,
    );
    if (outcome == null) {
      return const McpTransportResponse(
        statusCode: 404,
        headers: {},
        body: {'error': 'not_found'},
      );
    }
    return McpTransportResponse(
      statusCode: outcome.statusCode,
      headers: outcome.headers,
      body: outcome.body,
    );
  }
}

/// Client for dual-era MCP Streamable HTTP demos.
///
/// Legacy path: initialize + `Mcp-Session-Id` (`2025-03-26`) via
/// [runEchoDemo]. Current-official path: stateless `server/discover` +
/// `_meta` (`2026-07-28`) via [runModernEchoDemo].
///
/// Live JWT verification must not use the demo unsigned audience inspector
/// from the foundation fixtures.
class McpSessionClient {
  McpSessionClient({
    required this.transport,
    this.clientName = 'flutter-navigation-basic',
    this.clientVersion = '0.1.0',
  });

  final McpStreamableTransport transport;
  final String clientName;
  final String clientVersion;

  String? sessionId;
  String protocolVersion = McpProtocol.specificationVersion;
  int _nextId = 1;

  Future<JsonRpcResponse> initialize() async {
    final request = JsonRpcRequest(
      id: _nextId++,
      method: 'initialize',
      params: {
        'protocolVersion': McpProtocol.specificationVersion,
        'capabilities': <String, Object?>{},
        'clientInfo': {
          'name': clientName,
          'version': clientVersion,
        },
      },
    );
    final outcome = await _send(request);
    if (!outcome.response.isError) {
      sessionId = outcome.sessionId ?? sessionId;
      final result = outcome.response.result;
      if (result is Map && result['protocolVersion'] is String) {
        protocolVersion = result['protocolVersion'] as String;
      }
    }
    return outcome.response;
  }

  /// Sends `notifications/initialized` and returns the transport outcome.
  ///
  /// Callers must inspect [JsonRpcResponse.isError] — a rejected notification
  /// is never treated as success by [runEchoDemo].
  Future<JsonRpcResponse> notifyInitialized() async {
    return (await _send(
      const JsonRpcRequest(method: 'notifications/initialized'),
    )).response;
  }

  Future<JsonRpcResponse> listTools() {
    return _rpc(const JsonRpcRequest(method: 'tools/list'));
  }

  Future<JsonRpcResponse> callTool({
    required String name,
    Map<String, Object?> arguments = const {},
  }) {
    return _rpc(
      JsonRpcRequest(
        method: 'tools/call',
        params: {
          'name': name,
          'arguments': arguments,
        },
      ),
    );
  }

  Future<JsonRpcResponse> listResources() {
    return _rpc(const JsonRpcRequest(method: 'resources/list'));
  }

  Future<JsonRpcResponse> listPrompts() {
    return _rpc(const JsonRpcRequest(method: 'prompts/list'));
  }

  Future<JsonRpcResponse> ping() {
    return _rpc(const JsonRpcRequest(method: 'ping'));
  }

  /// initialize → notifications/initialized → tools/list → tools/call(echo).
  Future<McpDemoRunResult> runEchoDemo({String text = 'hello'}) async {
    final log = <String>[];
    final init = await initialize();
    log.add('initialize → ${jsonEncode(init.toJson())}');
    if (init.isError) {
      return McpDemoRunResult(ok: false, log: log, sessionId: sessionId);
    }
    final notified = await notifyInitialized();
    if (notified.isError) {
      log.add(
        'notifications/initialized → rejected '
        '${jsonEncode(notified.toJson())} (session=$sessionId)',
      );
      return McpDemoRunResult(ok: false, log: log, sessionId: sessionId);
    }
    log.add('notifications/initialized → accepted (session=$sessionId)');
    final listed = await listTools();
    log.add('tools/list → ${jsonEncode(listed.toJson())}');
    if (listed.isError) {
      return McpDemoRunResult(ok: false, log: log, sessionId: sessionId);
    }
    final called = await callTool(
      name: 'echo',
      arguments: {'text': text},
    );
    log.add('tools/call(echo) → ${jsonEncode(called.toJson())}');
    return McpDemoRunResult(
      ok: !called.isError,
      log: log,
      sessionId: sessionId,
      lastResponse: called,
    );
  }


  /// Current-official `2026-07-28` path: server/discover → tools/list → tools/call(echo).
  ///
  /// No initialize / session header. Each RPC carries `_meta` protocol version.
  Future<McpDemoRunResult> runModernEchoDemo({String text = 'hello'}) async {
    final log = <String>[];
    protocolVersion = McpProtocol.currentOfficialVersion;
    sessionId = null;

    final discover = await _rpc(
      JsonRpcRequest(
        method: 'server/discover',
        params: {
          '_meta': {
            'io.modelcontextprotocol/protocolVersion':
                McpProtocol.currentOfficialVersion,
            'io.modelcontextprotocol/clientInfo': {
              'name': clientName,
              'version': clientVersion,
            },
            'io.modelcontextprotocol/clientCapabilities': <String, Object?>{},
          },
        },
      ),
    );
    log.add('server/discover → ${jsonEncode(discover.toJson())}');
    if (discover.isError) {
      return McpDemoRunResult(ok: false, log: log, sessionId: sessionId);
    }

    Map<String, Object?> metaParams([Map<String, Object?>? extra]) => {
          '_meta': {
            'io.modelcontextprotocol/protocolVersion':
                McpProtocol.currentOfficialVersion,
            'io.modelcontextprotocol/clientInfo': {
              'name': clientName,
              'version': clientVersion,
            },
            'io.modelcontextprotocol/clientCapabilities': <String, Object?>{},
          },
          if (extra != null) ...extra,
        };

    final listed = await _rpc(
      JsonRpcRequest(method: 'tools/list', params: metaParams()),
    );
    log.add('tools/list → ${jsonEncode(listed.toJson())}');
    if (listed.isError) {
      return McpDemoRunResult(ok: false, log: log, sessionId: sessionId);
    }

    final called = await _rpc(
      JsonRpcRequest(
        method: 'tools/call',
        params: metaParams({
          'name': 'echo',
          'arguments': {'text': text},
        }),
      ),
    );
    log.add('tools/call(echo) → ${jsonEncode(called.toJson())}');
    return McpDemoRunResult(
      ok: !called.isError,
      log: log,
      sessionId: sessionId,
      lastResponse: called,
    );
  }

  Future<JsonRpcResponse> _rpc(JsonRpcRequest template) async {
    final request = JsonRpcRequest(
      id: _nextId++,
      method: template.method,
      params: template.params,
    );
    return (await _send(request)).response;
  }

  Future<({JsonRpcResponse response, String? sessionId})> _send(
    JsonRpcRequest request,
  ) async {
    String? mcpName;
    final params = request.params;
    if (params is Map) {
      if (request.method == 'tools/call' || request.method == 'prompts/get') {
        final name = params['name'];
        if (name is String) mcpName = name;
      } else if (request.method == 'resources/read') {
        final uri = params['uri'];
        if (uri is String) mcpName = uri;
      }
    }
    final headers = mcpStreamableHeaders(
      sessionId: sessionId,
      protocolVersion: protocolVersion,
      method: request.method,
      name: mcpName,
    );
    final transportResponse = await transport.post(
      headers: headers,
      body: jsonEncode(request.toJson()),
    );

    String? headerValue(String name) {
      final wanted = name.toLowerCase();
      for (final entry in transportResponse.headers.entries) {
        if (entry.key.toLowerCase() == wanted) return entry.value;
      }
      return null;
    }

    final returnedSession = headerValue(McpProtocol.sessionIdHeader);
    final httpOk = transportResponse.statusCode >= 200 &&
        transportResponse.statusCode < 300;

    if (request.isNotification) {
      // Notifications never adopt a session id from a rejected response.
      if (httpOk) {
        if (returnedSession != null && returnedSession.isNotEmpty) {
          sessionId = returnedSession;
        }
        return (
          response: JsonRpcResponse.result(id: null, result: null),
          sessionId: sessionId,
        );
      }
      return (
        response: JsonRpcResponse.failure(
          id: null,
          error: JsonRpcError(
            code: JsonRpcErrorCode.internalError,
            message: 'notification rejected',
            data: {
              'statusCode': transportResponse.statusCode,
              'body': transportResponse.body,
            },
          ),
        ),
        sessionId: sessionId,
      );
    }

    final body = transportResponse.body;
    JsonRpcResponse response;
    if (body is Map) {
      final map = Map<String, Object?>.from(body);
      if (map.containsKey('error') && !map.containsKey('jsonrpc')) {
        final status = transportResponse.statusCode;
        response = JsonRpcResponse.failure(
          id: request.id,
          error: JsonRpcError(
            code: status == 401
                ? JsonRpcErrorCode.unauthorized
                : status == 403
                    ? JsonRpcErrorCode.forbidden
                    : JsonRpcErrorCode.internalError,
            message: map['error']?.toString() ?? 'http_error',
            data: map,
          ),
        );
      } else {
        try {
          // Validate jsonrpc / result-xor-error / id correlation / error shape.
          response = JsonRpcResponse.parse(map, expectedId: request.id);
        } on FormatException catch (error) {
          response = JsonRpcResponse.failure(
            id: request.id,
            error: JsonRpcError(
              code: JsonRpcErrorCode.internalError,
              message: 'invalid JSON-RPC response: $error',
              data: {
                'statusCode': transportResponse.statusCode,
                'body': body,
              },
            ),
          );
        } on Object catch (error) {
          // External payloads must never surface as uncaught TypeError etc.
          response = JsonRpcResponse.failure(
            id: request.id,
            error: JsonRpcError(
              code: JsonRpcErrorCode.internalError,
              message: 'invalid JSON-RPC response: $error',
              data: {
                'statusCode': transportResponse.statusCode,
                'body': body,
              },
            ),
          );
        }
      }
    } else {
      response = JsonRpcResponse.failure(
        id: request.id,
        error: JsonRpcError(
          code: JsonRpcErrorCode.internalError,
          message: 'unexpected transport body',
          data: {
            'statusCode': transportResponse.statusCode,
            'body': body,
          },
        ),
      );
    }

    // HTTP error status must not be treated as success even if the body looks
    // like a JSON-RPC result. Do not retain a session header from failures
    // (including a failed initialize).
    if (!httpOk && !response.isError) {
      response = JsonRpcResponse.failure(
        id: request.id,
        error: JsonRpcError(
          code: transportResponse.statusCode == 401
              ? JsonRpcErrorCode.unauthorized
              : transportResponse.statusCode == 403
                  ? JsonRpcErrorCode.forbidden
                  : JsonRpcErrorCode.internalError,
          message: 'HTTP ${transportResponse.statusCode} with result-shaped body',
          data: {
            'statusCode': transportResponse.statusCode,
            'body': body,
          },
        ),
      );
    }

    if (httpOk && !response.isError) {
      if (returnedSession != null && returnedSession.isNotEmpty) {
        sessionId = returnedSession;
      }
    }

    return (response: response, sessionId: sessionId);
  }
}

class McpDemoRunResult {
  const McpDemoRunResult({
    required this.ok,
    required this.log,
    this.sessionId,
    this.lastResponse,
  });

  final bool ok;
  final List<String> log;
  final String? sessionId;
  final JsonRpcResponse? lastResponse;
}

/// Transport that posts JSON-RPC directly into [McpFoundationHandler].
///
/// Mirrors [MockMcpRoutes] dual-era HTTP status mapping: modern envelope
/// validation failures → HTTP 400; valid current-official unknown methods →
/// HTTP 404; legacy unknown methods → HTTP 200 + JSON-RPC `methodNotFound`.
class FoundationHandlerTransport implements McpStreamableTransport {
  FoundationHandlerTransport(this.handler);

  final McpFoundationHandler handler;

  @override
  Future<McpTransportResponse> post({
    required Map<String, String> headers,
    required String body,
  }) async {
    String? headerValue(String name) {
      final wanted = name.toLowerCase();
      for (final entry in headers.entries) {
        if (entry.key.toLowerCase() == wanted) return entry.value;
      }
      return null;
    }

    final request = JsonRpcRequest.tryParse(body);
    if (request == null) {
      return McpTransportResponse(
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

    final inbound = headerValue(McpProtocol.sessionIdHeader);
    final headerProtocol = headerValue(McpProtocol.protocolVersionHeader);
    final metaVersion = mcpMetaProtocolVersion(request);
    final looksModern = looksModernMcpRequest(
      request: request,
      headerProtocol: headerProtocol,
      metaVersion: metaVersion,
    );

    if (looksModern) {
      final modernError = validateModernMcpHttp(
        request: request,
        headerProtocol: headerProtocol,
        metaVersion: metaVersion,
        headerMethod: headerValue(McpProtocol.methodHeader),
        headerName: headerValue(McpProtocol.nameHeader),
      );
      if (modernError != null) {
        return McpTransportResponse(
          statusCode: 400,
          headers: {
            McpProtocol.protocolVersionHeader:
                McpProtocol.currentOfficialVersion,
          },
          body: modernError.toJson(),
        );
      }
    }

    final outcome = handler.handleRpc(
      request: request,
      sessionId: looksModern ? null : inbound,
    );

    final outHeaders = <String, String>{
      if (outcome.sessionId != null)
        McpProtocol.sessionIdHeader: outcome.sessionId!,
      McpProtocol.protocolVersionHeader: looksModern
          ? McpProtocol.currentOfficialVersion
          : McpProtocol.specificationVersion,
    };

    if (request.isNotification) {
      if (outcome.response.isError) {
        final code = outcome.response.error!.code;
        final status = switch (code) {
          JsonRpcErrorCode.unauthorized => 401,
          JsonRpcErrorCode.forbidden => 403,
          JsonRpcErrorCode.sessionRequired => 400,
          JsonRpcErrorCode.sessionInvalid => 404,
          _ => 400,
        };
        return McpTransportResponse(
          statusCode: status,
          headers: outHeaders,
          body: {
            'error': outcome.response.error!.message,
            'code': code,
          },
        );
      }
      return McpTransportResponse(
        statusCode: 202,
        headers: outHeaders,
        body: null,
      );
    }

    final err = outcome.response.error?.code;
    // Current-official Streamable HTTP: unimplemented RPC → HTTP 404.
    if (looksModern && err == JsonRpcErrorCode.methodNotFound) {
      return McpTransportResponse(
        statusCode: 404,
        headers: outHeaders,
        body: outcome.response.toJson(),
      );
    }
    final status = switch (err) {
      JsonRpcErrorCode.unauthorized => 401,
      JsonRpcErrorCode.forbidden => 403,
      JsonRpcErrorCode.sessionRequired => 400,
      JsonRpcErrorCode.sessionInvalid => 404,
      _ => 200,
    };
    return McpTransportResponse(
      statusCode: status,
      headers: outHeaders,
      body: outcome.response.toJson(),
    );
  }
}

