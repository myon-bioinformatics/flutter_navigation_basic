import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'auth_matrix.dart';
import 'request_draft.dart';
import 'request_field.dart';

/// Minimal auth-route handler contract (implemented by the toolkit mock).
typedef MockAuthRouteHandler = ({
  int statusCode,
  Map<String, Object?> body,
  Map<String, String> headers,
})? Function({
  required String method,
  required String path,
  required Map<String, String> headers,
  required Map<String, String> query,
  String? requestTarget,
});

/// Outcome of executing a [RequestDraft] against a local mock auth handler.
class RequestExecutionResult {
  const RequestExecutionResult({
    required this.statusCode,
    required this.body,
    this.headers = const {},
    this.requestTarget = '',
  });

  final int statusCode;
  final Map<String, Object?> body;
  final Map<String, String> headers;
  final String requestTarget;

  Map<String, Object?> toJson() => {
        'statusCode': statusCode,
        'headers': headers,
        'requestTarget': requestTarget,
        'body': body,
      };
}

/// Executes drafts in-process against a mock auth route handler (no network).
///
/// Live TLS (`-k`) / redirect (`-L`) policy and production JWT verification
/// remain #70 follow-ups — this path is mock-only and must not use the
/// unsigned foundation JWT inspector for live verification.
class MockAuthRequestExecutor {
  MockAuthRequestExecutor({
    required this.handler,
    this.hmacSecret = 'demo-hmac-secret',
    this.hmacKeyId = 'demo-key',
  });

  final MockAuthRouteHandler handler;
  final String hmacSecret;
  final String hmacKeyId;

  RequestExecutionResult execute(
    RequestDraft draft, {
    AuthMatrixScenario? scenario,
  }) {
    var prepared = draft;
    if (scenario == AuthMatrixScenario.hmac) {
      prepared = _signHmac(draft);
    }

    final uri = Uri.parse(prepared.normalizedUrl);
    final path = uri.path.isEmpty ? '/' : uri.path;
    final query = <String, String>{
      for (final field in prepared.enabledQuery)
        field.normalizedName: field.normalizedValue,
      ...uri.queryParameters,
    };
    final headers = <String, String>{
      for (final field in prepared.enabledHeaders)
        field.name.trim(): field.normalizedValue,
    };
    final target = uri.hasQuery ? '$path?${uri.query}' : path;

    final auth = handler(
      method: prepared.method.label,
      path: path,
      headers: headers,
      query: query,
      requestTarget: target,
    );
    if (auth == null) {
      return RequestExecutionResult(
        statusCode: 404,
        body: {'error': 'not_an_auth_route', 'path': path},
        requestTarget: target,
      );
    }
    return RequestExecutionResult(
      statusCode: auth.statusCode,
      body: auth.body,
      headers: auth.headers,
      requestTarget: target,
    );
  }

  /// Runs every auth-matrix scenario (except [AuthMatrixScenario.none]).
  List<({AuthMatrixScenario scenario, RequestExecutionResult result})>
      runMatrix({String baseUrl = 'http://127.0.0.1:8787'}) {
    final out =
        <({AuthMatrixScenario scenario, RequestExecutionResult result})>[];
    for (final scenario in AuthMatrixScenario.values) {
      if (scenario == AuthMatrixScenario.none) continue;
      final draft = scenario.applyTo(const RequestDraft(), baseUrl: baseUrl);
      out.add((scenario: scenario, result: execute(draft, scenario: scenario)));
    }
    return out;
  }

  RequestDraft _signHmac(RequestDraft draft) {
    final uri = Uri.parse(draft.normalizedUrl);
    final path = uri.path.isEmpty ? '/' : uri.path;
    final timestamp =
        (DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000).toString();
    final nonce = 'demo-nonce-${DateTime.now().toUtc().microsecondsSinceEpoch}';
    final method = draft.method.label;
    final payload = '$method\n$path\n$timestamp\n$nonce';
    final digest =
        Hmac(sha256, utf8.encode(hmacSecret)).convert(utf8.encode(payload));

    RequestField h(String name, String value, {bool sensitive = false}) =>
        RequestField(
          id: 'hmac-$name',
          name: name,
          value: value,
          sensitive: sensitive,
        );

    final headers = [
      for (final field in draft.enabledHeaders)
        if (field.normalizedName != 'x-key-id' &&
            field.normalizedName != 'x-timestamp' &&
            field.normalizedName != 'x-nonce' &&
            field.normalizedName != 'x-signature')
          field,
      h('X-Key-Id', hmacKeyId),
      h('X-Timestamp', timestamp),
      h('X-Nonce', nonce),
      h('X-Signature', digest.toString(), sensitive: true),
    ];
    return draft.copyWith(headers: headers);
  }
}

/// Builds a receipt string for an execution result.
String formatExecutionReceipt({
  required RequestDraft draft,
  required RequestExecutionResult result,
  required String redactedCurl,
}) {
  final body = const JsonEncoder.withIndent('  ').convert(result.toJson());
  return 'request-target: ${result.requestTarget}\n'
      'status: ${result.statusCode}\n'
      'curl (redacted):\n$redactedCurl\n\n'
      'response:\n$body';
}
