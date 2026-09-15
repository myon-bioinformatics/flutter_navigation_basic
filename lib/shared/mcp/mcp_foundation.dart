import 'dart:convert';
import 'dart:math';

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
  String? method,
  String? name,
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
    if (method != null && method.isNotEmpty) McpProtocol.methodHeader: method,
    if (name != null && name.isNotEmpty)
      McpProtocol.nameHeader: McpHeaderCodec.encode(name),
  };
}

/// Generates a high-entropy, URL-safe session id (base64url, no padding).
String generateMcpSessionId({Random? random, int byteLength = 18}) {
  final rng = random ?? Random.secure();
  final bytes = List<int>.generate(byteLength, (_) => rng.nextInt(256));
  return base64Url.encode(bytes).replaceAll('=', '');
}

/// Demo MCP method dispatcher used by unit tests and the local mock server.
///
/// This is a foundation stub — not a full MCP host. It covers initialize,
/// tools/list, tools/call, resources/list|read, prompts/list|get, and ping.
class McpFoundationHandler {
  McpFoundationHandler({
    String Function()? sessionIdFactory,
  }) : _sessionIdFactory = sessionIdFactory ?? generateMcpSessionId;

  final String Function() _sessionIdFactory;
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
        // Stateful Streamable HTTP: initialized also requires the issued session.
        return _requireSession(request, sessionId, (_) {
          return JsonRpcResponse.result(id: request.id, result: null);
        });
      case 'ping':
        return _requireSession(request, sessionId, (_) {
          return JsonRpcResponse.result(
            id: request.id,
            result: <String, Object?>{},
          );
        });
      case 'tools/list':
        return _modernOrSession(
          request,
          sessionId,
          (_) {
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
          },
          listResult: true,
        );
      case 'tools/call':
        return _modernOrSession(request, sessionId, (_) {
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
        return _modernOrSession(
          request,
          sessionId,
          (_) {
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
          },
          listResult: true,
        );
      case 'resources/read':
        return _modernOrSession(request, sessionId, (_) {
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
        return _modernOrSession(
          request,
          sessionId,
          (_) {
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
          },
          listResult: true,
        );
      case 'prompts/get':
        return _modernOrSession(request, sessionId, (_) {
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
      case 'server/discover':
        return _serverDiscover(request);
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
    final params = _asMap(request.params);
    if (params == null) {
      return _invalidInitialize(
        request,
        'initialize params must be an object',
      );
    }

    // Required InitializeRequest fields (MCP lifecycle). Wrong/missing types
    // are invalidParams and must not allocate a session. An unsupported
    // *string* protocolVersion still negotiates successfully to the pin.
    final protocolVersion = params['protocolVersion'];
    if (protocolVersion is! String || protocolVersion.isEmpty) {
      return _invalidInitialize(
        request,
        'protocolVersion must be a non-empty string',
      );
    }
    final capabilities = _asMap(params['capabilities']);
    if (capabilities == null) {
      return _invalidInitialize(
        request,
        'capabilities must be an object',
      );
    }
    final clientInfo = _asMap(params['clientInfo']);
    if (clientInfo == null) {
      return _invalidInitialize(
        request,
        'clientInfo must be an object',
      );
    }
    // Implementation info requires string name + version (MCP InitializeRequest).
    final clientName = clientInfo['name'];
    final clientVersion = clientInfo['version'];
    if (clientName is! String || clientName.isEmpty) {
      return _invalidInitialize(
        request,
        'clientInfo.name must be a non-empty string',
      );
    }
    if (clientVersion is! String || clientVersion.isEmpty) {
      return _invalidInitialize(
        request,
        'clientInfo.version must be a non-empty string',
      );
    }

    final id = _sessionIdFactory();
    _sessions[id] = McpSession(
      id: id,
      protocolVersion: McpProtocol.specificationVersion,
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

  ({JsonRpcResponse response, String? sessionId}) _invalidInitialize(
    JsonRpcRequest request,
    String message,
  ) {
    return (
      response: JsonRpcResponse.failure(
        id: request.id,
        error: JsonRpcError(
          code: JsonRpcErrorCode.invalidParams,
          message: message,
        ),
      ),
      sessionId: null,
    );
  }


  ({JsonRpcResponse response, String? sessionId}) _serverDiscover(
    JsonRpcRequest request,
  ) {
    return (
      response: JsonRpcResponse.result(
        id: request.id,
        result: {
          'resultType': 'complete',
          'protocolVersions': [
            McpProtocol.specificationVersion,
            McpProtocol.currentOfficialVersion,
          ],
          'capabilities': {
            'tools': {'listChanged': false},
            'resources': {'subscribe': false, 'listChanged': false},
            'prompts': {'listChanged': false},
          },
          'serverInfo': {
            'name': 'flutter-navigation-basic-mcp-foundation',
            'version': '0.1.0',
          },
          'instructions':
              'Dual-era demo server. Prefer '
              '${McpProtocol.currentOfficialVersion} with per-request _meta, '
              'or legacy initialize + session.',
        },
      ),
      sessionId: null,
    );
  }

  bool _hasModernMeta(JsonRpcRequest request) {
    final params = _asMap(request.params);
    final meta = _asMap(params?['_meta']);
    if (meta == null) return false;
    final version = meta['io.modelcontextprotocol/protocolVersion'];
    return version == McpProtocol.currentOfficialVersion;
  }

  ({JsonRpcResponse response, String? sessionId}) _modernOrSession(
    JsonRpcRequest request,
    String? sessionId,
    JsonRpcResponse Function(McpSession? session) build, {
    bool listResult = false,
  }) {
    if (_hasModernMeta(request)) {
      final response = build(null);
      return (
        response: _withModernResultShape(
          response,
          listResult: listResult,
        ),
        sessionId: null,
      );
    }
    return _requireSession(request, sessionId, (session) => build(session));
  }

  /// Current-official results require `resultType`; list results also carry
  /// cache hint fields (`ttlMs`, `cacheScope`).
  JsonRpcResponse _withModernResultShape(
    JsonRpcResponse response, {
    bool listResult = false,
  }) {
    if (response.isError) return response;
    final result = response.result;
    if (result is! Map) {
      return JsonRpcResponse.result(
        id: response.id,
        result: {
          'resultType': 'complete',
          'value': result,
        },
      );
    }
    final map = Map<String, Object?>.from(result);
    map.putIfAbsent('resultType', () => 'complete');
    if (listResult) {
      map.putIfAbsent('ttlMs', () => 60000);
      map.putIfAbsent('cacheScope', () => 'private');
    }
    return JsonRpcResponse.result(id: response.id, result: map);
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
}

enum BearerGateStatus { ok, unauthorized, forbidden }

class BearerGate {
  const BearerGate({required this.status, required this.reason});

  final BearerGateStatus status;
  final String reason;

  static const ok = BearerGate(status: BearerGateStatus.ok, reason: 'ok');
}
