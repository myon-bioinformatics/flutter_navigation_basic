import 'json_rpc.dart';
import 'mcp_protocol.dart';

/// In-memory MCP session after a successful `initialize`.
class McpSession {
  McpSession({
    required this.id,
    required this.protocolVersion,
    required this.clientInfo,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toUtc();

  final String id;
  final String protocolVersion;
  final Map<String, Object?> clientInfo;
  final DateTime createdAt;
}

/// Builds Streamable HTTP headers for an MCP JSON-RPC POST.
Map<String, String> mcpStreamableHeaders({
  String? sessionId,
  String protocolVersion = McpProtocol.specificationVersion,
  bool acceptEventStream = true,
}) {
  final accept = acceptEventStream
      ? '${McpProtocol.acceptJson}, ${McpProtocol.acceptEventStream}'
      : McpProtocol.acceptJson;
  return {
    'content-type': McpProtocol.acceptJson,
    'accept': accept,
    McpProtocol.protocolVersionHeader: protocolVersion,
    if (sessionId != null && sessionId.isNotEmpty)
      McpProtocol.sessionIdHeader: sessionId,
  };
}

/// Demo MCP method dispatcher used by unit tests and the local mock server.
///
/// This is a foundation stub — not a full MCP host. It covers initialize,
/// tools/list, tools/call, resources/list|read, prompts/list|get, and ping.
class McpFoundationHandler {
  McpFoundationHandler({
    String Function()? sessionIdFactory,
    this.requiredAudience,
  }) : _sessionIdFactory = sessionIdFactory ?? _defaultSessionId;

  final String Function() _sessionIdFactory;
  final String? requiredAudience;
  final Map<String, McpSession> _sessions = {};

  McpSession? session(String id) => _sessions[id];

  /// Handles one JSON-RPC request. [sessionId] is the inbound `Mcp-Session-Id`.
  /// Returns the JSON-RPC response plus optional session id to set on HTTP.
  ({JsonRpcResponse response, String? sessionId}) handleRpc({
    required JsonRpcRequest request,
    String? sessionId,
    BearerGate? bearer,
  }) {
    if (bearer != null && bearer.status != BearerGateStatus.ok) {
      return (
        response: JsonRpcResponse.failure(
          id: request.id,
          error: JsonRpcError(
            code: bearer.status == BearerGateStatus.forbidden
                ? JsonRpcErrorCode.forbidden
                : JsonRpcErrorCode.unauthorized,
            message: bearer.status.name,
            data: {'reason': bearer.reason},
          ),
        ),
        sessionId: sessionId,
      );
    }

    switch (request.method) {
      case 'initialize':
        return _initialize(request);
      case 'notifications/initialized':
        return (
          response: JsonRpcResponse.result(id: request.id, result: null),
          sessionId: sessionId,
        );
      case 'ping':
        return _requireSession(request, sessionId, (_) {
          return JsonRpcResponse.result(id: request.id, result: <String, Object?>{});
        });
      case 'tools/list':
        return _requireSession(request, sessionId, (_) {
          return JsonRpcResponse.result(
            id: request.id,
            result: {
              'tools': [
                {
                  'name': 'echo',
                  'description': 'Echo a string argument',
                  'inputSchema': {
                    'type': 'object',
                    'properties': {
                      'text': {'type': 'string'},
                    },
                    'required': ['text'],
                  },
                },
              ],
            },
          );
        });
      case 'tools/call':
        return _requireSession(request, sessionId, (_) {
          final params = _asMap(request.params);
          final name = params?['name'];
          final args = _asMap(params?['arguments']) ?? const {};
          if (name != 'echo') {
            return JsonRpcResponse.failure(
              id: request.id,
              error: const JsonRpcError(
                code: JsonRpcErrorCode.invalidParams,
                message: 'unknown tool',
              ),
            );
          }
          final text = args['text'];
          if (text is! String) {
            return JsonRpcResponse.failure(
              id: request.id,
              error: const JsonRpcError(
                code: JsonRpcErrorCode.invalidParams,
                message: 'missing text',
              ),
            );
          }
          return JsonRpcResponse.result(
            id: request.id,
            result: {
              'content': [
                {'type': 'text', 'text': text},
              ],
              'isError': false,
            },
          );
        });
      case 'resources/list':
        return _requireSession(request, sessionId, (_) {
          return JsonRpcResponse.result(
            id: request.id,
            result: {
              'resources': [
                {
                  'uri': 'demo://readme',
                  'name': 'README',
                  'mimeType': 'text/plain',
                },
              ],
            },
          );
        });
      case 'resources/read':
        return _requireSession(request, sessionId, (_) {
          final params = _asMap(request.params);
          final uri = params?['uri'];
          if (uri != 'demo://readme') {
            return JsonRpcResponse.failure(
              id: request.id,
              error: const JsonRpcError(
                code: JsonRpcErrorCode.invalidParams,
                message: 'unknown resource',
              ),
            );
          }
          return JsonRpcResponse.result(
            id: request.id,
            result: {
              'contents': [
                {
                  'uri': uri,
                  'mimeType': 'text/plain',
                  'text': 'MCP foundation demo resource',
                },
              ],
            },
          );
        });
      case 'prompts/list':
        return _requireSession(request, sessionId, (_) {
          return JsonRpcResponse.result(
            id: request.id,
            result: {
              'prompts': [
                {
                  'name': 'greet',
                  'description': 'Greeting prompt',
                },
              ],
            },
          );
        });
      case 'prompts/get':
        return _requireSession(request, sessionId, (_) {
          final params = _asMap(request.params);
          final name = params?['name'];
          if (name != 'greet') {
            return JsonRpcResponse.failure(
              id: request.id,
              error: const JsonRpcError(
                code: JsonRpcErrorCode.invalidParams,
                message: 'unknown prompt',
              ),
            );
          }
          return JsonRpcResponse.result(
            id: request.id,
            result: {
              'description': 'Greeting prompt',
              'messages': [
                {
                  'role': 'user',
                  'content': {
                    'type': 'text',
                    'text': 'Hello from MCP foundation',
                  },
                },
              ],
            },
          );
        });
      default:
        return (
          response: JsonRpcResponse.failure(
            id: request.id,
            error: JsonRpcError(
              code: JsonRpcErrorCode.methodNotFound,
              message: 'method not found: ${request.method}',
            ),
          ),
          sessionId: sessionId,
        );
    }
  }

  ({JsonRpcResponse response, String? sessionId}) _initialize(
    JsonRpcRequest request,
  ) {
    final params = _asMap(request.params) ?? const {};
    final clientInfo = _asMap(params['clientInfo']) ??
        const <String, Object?>{'name': 'unknown', 'version': '0'};
    final requested = params['protocolVersion'] as String? ??
        McpProtocol.specificationVersion;
    // Negotiate: only the pinned version is accepted by this foundation stub.
    if (requested != McpProtocol.specificationVersion) {
      return (
        response: JsonRpcResponse.failure(
          id: request.id,
          error: JsonRpcError(
            code: JsonRpcErrorCode.invalidParams,
            message: 'unsupported protocol version',
            data: {
              'requested': requested,
              'supported': [McpProtocol.specificationVersion],
            },
          ),
        ),
        sessionId: null,
      );
    }
    final id = _sessionIdFactory();
    _sessions[id] = McpSession(
      id: id,
      protocolVersion: requested,
      clientInfo: clientInfo,
    );
    return (
      response: JsonRpcResponse.result(
        id: request.id,
        result: {
          'protocolVersion': McpProtocol.specificationVersion,
          'capabilities': {
            'tools': {'listChanged': false},
            'resources': {'subscribe': false, 'listChanged': false},
            'prompts': {'listChanged': false},
          },
          'serverInfo': {
            'name': 'flutter-navigation-basic-mcp-foundation',
            'version': '0.1.0',
          },
        },
      ),
      sessionId: id,
    );
  }

  ({JsonRpcResponse response, String? sessionId}) _requireSession(
    JsonRpcRequest request,
    String? sessionId,
    JsonRpcResponse Function(McpSession session) build,
  ) {
    if (sessionId == null || sessionId.isEmpty) {
      return (
        response: JsonRpcResponse.failure(
          id: request.id,
          error: const JsonRpcError(
            code: JsonRpcErrorCode.sessionRequired,
            message: 'Mcp-Session-Id required',
          ),
        ),
        sessionId: sessionId,
      );
    }
    final session = _sessions[sessionId];
    if (session == null) {
      return (
        response: JsonRpcResponse.failure(
          id: request.id,
          error: const JsonRpcError(
            code: JsonRpcErrorCode.sessionInvalid,
            message: 'unknown session',
          ),
        ),
        sessionId: sessionId,
      );
    }
    return (response: build(session), sessionId: sessionId);
  }

  static Map<String, Object?>? _asMap(Object? value) {
    if (value is Map<String, Object?>) return value;
    if (value is Map) return Map<String, Object?>.from(value);
    return null;
  }

  static String _defaultSessionId() =>
      'mcp-${DateTime.now().toUtc().microsecondsSinceEpoch}';
}

enum BearerGateStatus { ok, unauthorized, forbidden }

class BearerGate {
  const BearerGate({required this.status, required this.reason});

  final BearerGateStatus status;
  final String reason;

  static const ok = BearerGate(status: BearerGateStatus.ok, reason: 'ok');
}
