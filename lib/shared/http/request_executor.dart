import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'auth_matrix.dart';
import 'request_draft.dart';
import 'request_draft_codec.dart';
import 'request_field.dart';

/// Ordered query pair used for canonical request-target / HMAC binding.
typedef QueryPair = ({String name, String value});

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
  required List<QueryPair> queryPairs,
  String? requestTarget,
  String? body,
});

/// Outcome of executing a [RequestDraft] against a local mock auth handler.
class RequestExecutionResult {
  const RequestExecutionResult({
    required this.statusCode,
    required this.body,
    this.headers = const {},
    this.requestTarget = '',
    this.executionPath = 'direct',
    this.wireDraft,
  });

  final int statusCode;
  final Map<String, Object?> body;
  final Map<String, String> headers;
  final String requestTarget;

  /// Which preparation/dispatch path produced this result
  /// (`direct`, `hmac`, `digest-challenge`, `digest-retry`, `live`, …).
  final String executionPath;

  /// Final wire draft after auth preparation (HMAC sign / Digest retry).
  final RequestDraft? wireDraft;

  Map<String, Object?> toJson() => {
        'statusCode': statusCode,
        'headers': headers,
        'requestTarget': requestTarget,
        'executionPath': executionPath,
        'body': body,
      };

  RequestExecutionResult copyWith({
    int? statusCode,
    Map<String, Object?>? body,
    Map<String, String>? headers,
    String? requestTarget,
    String? executionPath,
    RequestDraft? wireDraft,
  }) {
    return RequestExecutionResult(
      statusCode: statusCode ?? this.statusCode,
      body: body ?? this.body,
      headers: headers ?? this.headers,
      requestTarget: requestTarget ?? this.requestTarget,
      executionPath: executionPath ?? this.executionPath,
      wireDraft: wireDraft ?? this.wireDraft,
    );
  }
}

/// Executes drafts in-process against a mock auth route handler (no network).
///
/// Live TLS (`-k`) / redirect (`-L`) policy and production JWT verification
/// remain follow-ups — this path is mock-only and must not use the unsigned
/// foundation JWT inspector for live verification.
/// Final wire snapshot after transport-independent auth preparation.
class AuthWireSnapshot {
  const AuthWireSnapshot({
    required this.draft,
    required this.path,
  });

  final RequestDraft draft;
  final String path;
}

class MockAuthRequestExecutor {
  MockAuthRequestExecutor({
    required this.handler,
    this.hmacSecret = 'demo-hmac-secret',
    this.hmacKeyId = 'demo-key',
    this.digestUsername = 'demo',
    this.digestPassword = 's3cret',
  });

  final MockAuthRouteHandler handler;
  final String hmacSecret;
  final String hmacKeyId;
  final String digestUsername;
  final String digestPassword;

  RequestExecutionResult execute(
    RequestDraft draft, {
    AuthMatrixScenario? scenario,
  }) {
    final prepared = prepareWireDraft(draft, scenario: scenario);
    var path = scenario == AuthMatrixScenario.hmac ? 'hmac' : 'direct';
    var result = _dispatch(prepared.draft);

    if (scenario == AuthMatrixScenario.digest) {
      if (result.statusCode != 401) {
        return result.copyWith(
          executionPath: 'digest-challenge',
          wireDraft: prepared.draft,
        );
      }
      final challenge = _header(result.headers, 'www-authenticate');
      if (challenge == null || !challenge.toLowerCase().startsWith('digest ')) {
        return result.copyWith(
          executionPath: 'digest-challenge',
          wireDraft: prepared.draft,
        );
      }
      final authed = applyDigestChallenge(
        prepared.draft,
        wwwAuthenticate: challenge,
        requestTarget: result.requestTarget,
      );
      result = _dispatch(authed);
      return result.copyWith(
        executionPath: 'digest-retry',
        wireDraft: authed,
      );
    }

    return result.copyWith(
      executionPath: path,
      wireDraft: prepared.draft,
    );
  }

  /// Transport-independent auth preparation shared by mock, live, and curl.
  AuthWireSnapshot prepareWireDraft(
    RequestDraft draft, {
    AuthMatrixScenario? scenario,
  }) {
    if (scenario == AuthMatrixScenario.hmac) {
      return AuthWireSnapshot(
        draft: signHmac(draft),
        path: 'hmac',
      );
    }
    return AuthWireSnapshot(draft: draft, path: 'direct');
  }

  /// Completes a Digest challenge against an arbitrary dispatcher (mock/live).
  Future<RequestExecutionResult> executePrepared(
    RequestDraft draft, {
    AuthMatrixScenario? scenario,
    required Future<RequestExecutionResult> Function(RequestDraft draft)
        dispatch,
    String basePath = 'live',
  }) async {
    final prepared = prepareWireDraft(draft, scenario: scenario);
    var result = await dispatch(prepared.draft);
    if (scenario != AuthMatrixScenario.digest) {
      return result.copyWith(
        executionPath: prepared.path == 'hmac' ? 'hmac-$basePath' : basePath,
        wireDraft: prepared.draft,
      );
    }
    if (result.statusCode != 401) {
      return result.copyWith(
        executionPath: '$basePath-digest-challenge',
        wireDraft: prepared.draft,
      );
    }
    final challenge = _header(result.headers, 'www-authenticate');
    if (challenge == null || !challenge.toLowerCase().startsWith('digest ')) {
      return result.copyWith(
        executionPath: '$basePath-digest-challenge',
        wireDraft: prepared.draft,
      );
    }
    final authed = applyDigestChallenge(
      prepared.draft,
      wwwAuthenticate: challenge,
      requestTarget: result.requestTarget,
    );
    result = await dispatch(authed);
    return result.copyWith(
      executionPath: '$basePath-digest-retry',
      wireDraft: authed,
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

  /// Public so negative tests can mint a valid signature then tamper with it.
  RequestDraft signHmac(
    RequestDraft draft, {
    String? timestamp,
    String? nonce,
    String? secret,
    String? keyId,
  }) {
    final pairs = orderedQueryPairs(draft);
    final path = _pathOf(draft);
    final queryString = encodeQueryPairs(pairs);
    final body = RequestDraftCodec.buildBody(draft, redactSecrets: false) ?? '';
    final ts = timestamp ??
        (DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000).toString();
    final n = nonce ??
        'demo-nonce-${DateTime.now().toUtc().microsecondsSinceEpoch}';
    final method = draft.method.label;
    final payload = canonicalHmacPayload(
      method: method,
      path: path,
      queryString: queryString,
      body: body,
      timestamp: ts,
      nonce: n,
    );
    final digest = Hmac(sha256, utf8.encode(secret ?? hmacSecret))
        .convert(utf8.encode(payload));

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
      h('X-Key-Id', keyId ?? hmacKeyId),
      h('X-Timestamp', ts),
      h('X-Nonce', n),
      h('X-Signature', digest.toString(), sensitive: true),
    ];
    return draft.copyWith(headers: headers);
  }

  /// Builds a Digest Authorization header from a WWW-Authenticate challenge.
  RequestDraft applyDigestChallenge(
    RequestDraft draft, {
    required String wwwAuthenticate,
    required String requestTarget,
    String nc = '00000001',
    String cnonce = 'demo-cnonce',
  }) {
    final params = _parseDigestChallenge(wwwAuthenticate);
    final realm = params['realm'] ?? '';
    final nonce = params['nonce'] ?? '';
    final opaque = params['opaque'] ?? '';
    final qop = params['qop']?.split(',').map((e) => e.trim()).firstWhere(
          (e) => e == 'auth',
          orElse: () => 'auth',
        ) ??
        'auth';
    final response = digestResponse(
      method: draft.method.label,
      uri: requestTarget,
      username: digestUsername,
      password: digestPassword,
      realm: realm,
      nonce: nonce,
      nc: nc,
      cnonce: cnonce,
      qop: qop,
    );
    final auth =
        'Digest username="$digestUsername", realm="$realm", nonce="$nonce", '
        'uri="$requestTarget", algorithm=MD5, qop=$qop, nc=$nc, '
        'cnonce="$cnonce", response="$response", opaque="$opaque"';
    final headers = [
      for (final field in draft.enabledHeaders)
        if (field.normalizedName != 'authorization') field,
      RequestField(
        id: 'auth-digest',
        name: 'Authorization',
        value: auth,
        sensitive: true,
      ),
    ];
    return draft.copyWith(headers: headers);
  }

  RequestExecutionResult _dispatch(RequestDraft draft) {
    final pairs = orderedQueryPairs(draft);
    final path = _pathOf(draft);
    final queryString = encodeQueryPairs(pairs);
    final target = queryString.isEmpty ? path : '$path?$queryString';
    final body = RequestDraftCodec.buildBody(draft, redactSecrets: false);
    final headers = <String, String>{
      for (final field in draft.enabledHeaders)
        field.name.trim(): field.normalizedValue,
    };
    // Collapsed map for handlers that only need last-wins lookup (API key).
    final query = <String, String>{
      for (final pair in pairs) pair.name: pair.value,
    };

    final auth = handler(
      method: draft.method.label,
      path: path,
      headers: headers,
      query: query,
      queryPairs: pairs,
      requestTarget: target,
      body: body,
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

  static String _pathOf(RequestDraft draft) {
    final uri = Uri.tryParse(draft.normalizedUrl);
    if (uri == null || uri.path.isEmpty) return '/';
    return uri.path;
  }

  /// URL query pairs first (raw order), then enabled draft query rows.
  static List<QueryPair> orderedQueryPairs(RequestDraft draft) {
    final uri = Uri.tryParse(draft.normalizedUrl);
    final pairs = <QueryPair>[
      if (uri != null)
        for (final pair in _parseQueryPairs(uri.query))
          (name: pair.name, value: pair.value),
      for (final field in draft.enabledQuery)
        (
          name: normalizeAsciiName(field.name),
          value: field.normalizedValue,
        ),
    ];
    return pairs;
  }

  static String encodeQueryPairs(List<QueryPair> pairs) {
    if (pairs.isEmpty) return '';
    return pairs
        .map(
          (p) =>
              '${Uri.encodeQueryComponent(p.name)}=${Uri.encodeQueryComponent(p.value)}',
        )
        .join('&');
  }

  static String canonicalHmacPayload({
    required String method,
    required String path,
    required String queryString,
    required String body,
    required String timestamp,
    required String nonce,
  }) {
    return '${method.toUpperCase()}\n$path\n$queryString\n$body\n$timestamp\n$nonce';
  }

  static String digestResponse({
    required String method,
    required String uri,
    required String username,
    required String password,
    required String realm,
    required String nonce,
    required String nc,
    required String cnonce,
    String qop = 'auth',
  }) {
    final ha1 = md5.convert(utf8.encode('$username:$realm:$password')).toString();
    final ha2 = md5.convert(utf8.encode('$method:$uri')).toString();
    return md5
        .convert(utf8.encode('$ha1:$nonce:$nc:$cnonce:$qop:$ha2'))
        .toString();
  }

  static String normalizeAsciiName(String name) {
    // Keep wire casing for query names; only strip fullwidth + trim.
    return name
        .replaceAllMapped(
          RegExp(r'[\uff01-\uff5e]'),
          (m) => String.fromCharCode(m.group(0)!.codeUnitAt(0) - 0xfee0),
        )
        .trim();
  }

  static List<({String name, String value})> _parseQueryPairs(String query) {
    if (query.isEmpty) return const [];
    final pairs = <({String name, String value})>[];
    for (final part in query.split('&')) {
      if (part.isEmpty) continue;
      final eq = part.indexOf('=');
      if (eq < 0) {
        pairs.add((name: Uri.decodeQueryComponent(part), value: ''));
        continue;
      }
      pairs.add((
        name: Uri.decodeQueryComponent(part.substring(0, eq)),
        value: Uri.decodeQueryComponent(part.substring(eq + 1)),
      ));
    }
    return pairs;
  }

  static Map<String, String> _parseDigestChallenge(String raw) {
    final out = <String, String>{};
    final pattern = RegExp(r'(\w+)=(?:"([^"]*)"|([^\s,]+))');
    final body = raw.toLowerCase().startsWith('digest ')
        ? raw.substring(7)
        : raw;
    for (final match in pattern.allMatches(body)) {
      out[match.group(1)!] = match.group(2) ?? match.group(3) ?? '';
    }
    return out;
  }

  static String? _header(Map<String, String> headers, String name) {
    final wanted = name.toLowerCase();
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == wanted) return entry.value;
    }
    return null;
  }
}

/// Builds a secret-safe receipt string for an execution result.
String formatExecutionReceipt({
  required RequestDraft draft,
  required RequestExecutionResult result,
  required String redactedCurl,
}) {
  final safe = redactExecutionResult(result);
  final body = const JsonEncoder.withIndent('  ').convert(safe);
  final wire = result.wireDraft ?? draft;
  final redactedTarget = redactRequestTarget(result.requestTarget, wire);
  return 'request-target: $redactedTarget\n'
      'execution-path: ${result.executionPath}\n'
      'status: ${result.statusCode}\n'
      'curl (redacted):\n$redactedCurl\n\n'
      'response:\n$body';
}

/// Redacts sensitive response headers, request-target secrets, and body fields.
Map<String, Object?> redactExecutionResult(RequestExecutionResult result) {
  final headers = <String, String>{};
  for (final entry in result.headers.entries) {
    headers[entry.key] = RequestDraftCodec.isSensitiveFieldName(entry.key)
        ? '***'
        : entry.value;
  }
  final wire = result.wireDraft;
  return {
    'statusCode': result.statusCode,
    'executionPath': result.executionPath,
    'headers': headers,
    'requestTarget': redactRequestTarget(result.requestTarget, wire),
    'body': redactJsonValue(result.body),
  };
}

/// Redacts secret-bearing query pairs in a request-target / path+query string.
String redactRequestTarget(String requestTarget, [RequestDraft? draft]) {
  if (draft != null) {
    final uri = RequestDraftCodec.buildUri(draft, redactSecrets: true);
    if (uri != null) {
      return uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
    }
  }
  final q = requestTarget.indexOf('?');
  if (q < 0) return requestTarget;
  final path = requestTarget.substring(0, q);
  final query = requestTarget.substring(q + 1);
  final pairs = <String>[];
  for (final part in query.split('&')) {
    if (part.isEmpty) continue;
    final eq = part.indexOf('=');
    final rawName = eq < 0 ? part : part.substring(0, eq);
    final rawValue = eq < 0 ? '' : part.substring(eq + 1);
    final name = Uri.decodeQueryComponent(rawName);
    if (RequestDraftCodec.isSensitiveFieldName(name)) {
      pairs.add('$rawName=***');
    } else {
      pairs.add(eq < 0 ? rawName : '$rawName=$rawValue');
    }
  }
  return pairs.isEmpty ? path : '$path?${pairs.join('&')}';
}

Object? redactJsonValue(Object? value) {
  if (value is Map) {
    final out = <String, Object?>{};
    for (final entry in value.entries) {
      final key = entry.key.toString();
      if (RequestDraftCodec.isSensitiveFieldName(key)) {
        out[key] = '***';
      } else {
        out[key] = redactJsonValue(entry.value);
      }
    }
    return out;
  }
  if (value is List) {
    return [for (final item in value) redactJsonValue(item)];
  }
  return value;
}
