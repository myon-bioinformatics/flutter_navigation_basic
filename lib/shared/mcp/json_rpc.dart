import 'dart:convert';

/// JSON-RPC 2.0 error codes (plus MCP-aligned application range helpers).
abstract final class JsonRpcErrorCode {
  static const parseError = -32700;
  static const invalidRequest = -32600;
  static const methodNotFound = -32601;
  static const invalidParams = -32602;
  static const internalError = -32603;

  /// MCP-ish application errors (custom, documented for this foundation).
  static const unauthorized = -32001;
  static const forbidden = -32003;
  static const sessionRequired = -32010;
  static const sessionInvalid = -32011;

  /// Current-official Streamable HTTP header/body validation failures.
  static const headerMismatch = -32020;
  static const unsupportedProtocolVersion = -32022;
}

class JsonRpcError {
  const JsonRpcError({
    required this.code,
    required this.message,
    this.data,
  });

  final int code;
  final String message;
  final Object? data;

  Map<String, Object?> toJson() => {
        'code': code,
        'message': message,
        if (data != null) 'data': data,
      };

  factory JsonRpcError.fromJson(Map<String, Object?> json) {
    return JsonRpcError(
      code: json['code'] as int? ?? JsonRpcErrorCode.internalError,
      message: json['message'] as String? ?? 'error',
      data: json['data'],
    );
  }
}

/// One JSON-RPC 2.0 request (never a notification when [id] is non-null).
class JsonRpcRequest {
  const JsonRpcRequest({
    required this.method,
    this.id,
    this.params,
    this.jsonrpc = '2.0',
  });

  final String jsonrpc;
  final Object? id;
  final String method;
  final Object? params;

  bool get isNotification => id == null;

  Map<String, Object?> toJson() => {
        'jsonrpc': jsonrpc,
        if (id != null) 'id': id,
        'method': method,
        if (params != null) 'params': params,
      };

  factory JsonRpcRequest.fromJson(Map<String, Object?> json) {
    final version = json['jsonrpc'];
    final method = json['method'];
    if (version != '2.0' || method is! String || method.isEmpty) {
      throw const FormatException('invalid JSON-RPC request');
    }
    return JsonRpcRequest(
      jsonrpc: version as String,
      id: json['id'],
      method: method,
      params: json['params'],
    );
  }

  static JsonRpcRequest? tryParse(Object? raw) {
    try {
      if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, Object?>) {
          return JsonRpcRequest.fromJson(decoded);
        }
        if (decoded is Map) {
          return JsonRpcRequest.fromJson(Map<String, Object?>.from(decoded));
        }
        return null;
      }
      if (raw is Map<String, Object?>) return JsonRpcRequest.fromJson(raw);
      if (raw is Map) {
        return JsonRpcRequest.fromJson(Map<String, Object?>.from(raw));
      }
      return null;
    } on FormatException {
      return null;
    } on Object {
      return null;
    }
  }
}

class JsonRpcResponse {
  const JsonRpcResponse({
    required this.id,
    this.result,
    this.error,
    this.jsonrpc = '2.0',
  }) : assert(
          (result != null) ^ (error != null) || (result == null && error == null),
          'result and error are mutually exclusive unless both null for empty ack',
        );

  final String jsonrpc;
  final Object? id;
  final Object? result;
  final JsonRpcError? error;

  bool get isError => error != null;

  Map<String, Object?> toJson() => {
        'jsonrpc': jsonrpc,
        'id': id,
        if (error != null) 'error': error!.toJson(),
        if (error == null) 'result': result,
      };

  factory JsonRpcResponse.result({
    required Object? id,
    required Object? result,
  }) {
    return JsonRpcResponse(id: id, result: result);
  }

  factory JsonRpcResponse.failure({
    required Object? id,
    required JsonRpcError error,
  }) {
    return JsonRpcResponse(id: id, error: error);
  }

  factory JsonRpcResponse.fromJson(Map<String, Object?> json) {
    final version = json['jsonrpc'];
    if (version != '2.0') {
      throw const FormatException('invalid JSON-RPC response version');
    }
    final hasResult = json.containsKey('result');
    final hasError = json.containsKey('error');
    if (hasResult == hasError) {
      throw const FormatException(
        'JSON-RPC response must contain exactly one of result or error',
      );
    }
    if (hasError) {
      final errorJson = json['error'];
      if (errorJson is! Map) {
        throw const FormatException('invalid JSON-RPC error payload');
      }
      return JsonRpcResponse.failure(
        id: json['id'],
        error: JsonRpcError.fromJson(Map<String, Object?>.from(errorJson)),
      );
    }
    return JsonRpcResponse.result(
      id: json['id'],
      result: json['result'],
    );
  }

  /// Parses [json] and optionally checks that [expectedId] matches `id`.
  factory JsonRpcResponse.parse(
    Map<String, Object?> json, {
    Object? expectedId,
  }) {
    final response = JsonRpcResponse.fromJson(json);
    if (expectedId != null && response.id != expectedId) {
      throw FormatException(
        'JSON-RPC response id mismatch: expected $expectedId got ${response.id}',
      );
    }
    return response;
  }
}
