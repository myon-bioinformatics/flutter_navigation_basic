import 'dart:convert';

import 'json_rpc.dart';
import 'mcp_foundation.dart';
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

/// Client session for the pinned legacy MCP `2025-03-26` Streamable HTTP path.
///
/// Does **not** implement current-official `2026-07-28` (stateless /
/// `server/discover`). Live JWT verification must not use the demo unsigned
/// audience inspector from the foundation fixtures.
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

  Future<void> notifyInitialized() async {
    await _send(
      const JsonRpcRequest(method: 'notifications/initialized'),
    );
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
    await notifyInitialized();
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
    final headers = mcpStreamableHeaders(
      sessionId: sessionId,
      protocolVersion: protocolVersion,
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
    if (returnedSession != null && returnedSession.isNotEmpty) {
      sessionId = returnedSession;
    }

    if (request.isNotification) {
      if (transportResponse.statusCode >= 200 &&
          transportResponse.statusCode < 300) {
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
    if (body is Map) {
      final map = Map<String, Object?>.from(body);
      if (map.containsKey('error') && !map.containsKey('jsonrpc')) {
        final status = transportResponse.statusCode;
        return (
          response: JsonRpcResponse.failure(
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
          ),
          sessionId: sessionId,
        );
      }
      return (
        response: JsonRpcResponse.fromJson(map),
        sessionId: sessionId,
      );
    }

    return (
      response: JsonRpcResponse.failure(
        id: request.id,
        error: JsonRpcError(
          code: JsonRpcErrorCode.internalError,
          message: 'unexpected transport body',
          data: {
            'statusCode': transportResponse.statusCode,
            'body': body,
          },
        ),
      ),
      sessionId: sessionId,
    );
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
/// Keeps app UI free of `tool/` imports while still exercising the same
/// foundation session / method surface the mock HTTP route uses.
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
    final outcome = handler.handleRpc(
      request: request,
      sessionId: inbound,
    );

    final outHeaders = <String, String>{
      if (outcome.sessionId != null)
        McpProtocol.sessionIdHeader: outcome.sessionId!,
      McpProtocol.protocolVersionHeader: McpProtocol.specificationVersion,
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

