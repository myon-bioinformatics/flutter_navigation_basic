import 'json_rpc.dart';
import 'mcp_protocol.dart';

/// Reads `params._meta.io.modelcontextprotocol/protocolVersion` when present.
String? mcpMetaProtocolVersion(JsonRpcRequest request) {
  final params = request.params;
  if (params is! Map) return null;
  final meta = params['_meta'];
  if (meta is! Map) return null;
  final version = meta['io.modelcontextprotocol/protocolVersion'];
  return version is String ? version : null;
}

/// True when the request should be treated as current-official Streamable HTTP.
///
/// Markers match [MockMcpRoutes]: `server/discover`, body `_meta` protocol
/// version, or `MCP-Protocol-Version` equal to the current official revision.
bool looksModernMcpRequest({
  required JsonRpcRequest request,
  required String? headerProtocol,
  String? metaVersion,
}) {
  final resolvedMeta = metaVersion ?? mcpMetaProtocolVersion(request);
  return request.method == 'server/discover' ||
      resolvedMeta != null ||
      headerProtocol == McpProtocol.currentOfficialVersion;
}

/// Validates current-official Streamable HTTP headers against body `_meta`.
///
/// Returns a failure [JsonRpcResponse] when the envelope is invalid; callers
/// should map that to HTTP 400. Returns `null` when validation passes.
JsonRpcResponse? validateModernMcpHttp({
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
