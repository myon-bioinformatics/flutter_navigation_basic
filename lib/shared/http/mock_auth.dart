import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'digest_nc.dart';

/// Well-known **demo** credentials for local mock auth scenarios.
///
/// These are intentionally public fixture values — never real secrets.
class MockAuthDemo {
  const MockAuthDemo._();

  static const bearerToken = 'demo-bearer-token';
  static const bearerExpiredToken = 'demo-expired-token';
  static const bearerWrongAudienceToken = 'demo-wrong-aud-token';
  static const bearerAudience = 'https://api.example.test';

  static const apiKey = 'demo-api-key';
  static const apiKeyHeader = 'x-api-key';
  static const apiKeyQuery = 'api_key';

  static const basicUser = 'demo';
  static const basicPassword = 's3cret';
  static const basicRealm = 'mock';

  static const digestRealm = 'mock';
  static const digestNonce = 'demo-digest-nonce';
  static const digestOpaque = 'demo-digest-opaque';

  static const hmacKeyId = 'demo-key';
  static const hmacSecret = 'demo-hmac-secret';
  static const hmacMaxSkew = Duration(minutes: 5);
}

/// Result written by [MockAuthHandler] for a single request.
class MockAuthResult {
  const MockAuthResult({
    required this.statusCode,
    required this.body,
    this.headers = const {},
  });

  final int statusCode;
  final Map<String, Object?> body;
  final Map<String, String> headers;
}

/// Stateless-ish auth scenario router (nonce replay tracked in-memory).
class MockAuthHandler {
  MockAuthHandler({
    Set<String>? seenNonces,
    DateTime Function()? clock,
    Map<String, int>? digestNcByClient,
  })  : _seenNonces = seenNonces ?? <String>{},
        _clock = clock ?? DateTime.now,
        _digestNcByClient = digestNcByClient ?? <String, int>{};

  final Set<String> _seenNonces;
  final DateTime Function() _clock;

  /// Tracks highest accepted Digest `nc` per `nonce|cnonce` client tuple.
  /// Fixture MD5 Digest only — not for production auth.
  final Map<String, int> _digestNcByClient;

  /// Returns a result when [path] is an `/auth/...` scenario; otherwise null.
  ///
  /// [requestTarget] is the HTTP request-target (path + optional `?query`)
  /// used to bind Digest `uri=` / HA2. When omitted, it is derived from
  /// [path] and [query].
  MockAuthResult? handle({
    required String method,
    required String path,
    required Map<String, String> headers,
    required Map<String, String> query,
    String? requestTarget,
    String? body,
    List<({String name, String value})>? queryPairs,
  }) {
    final normalized = path.endsWith('/') && path.length > 1
        ? path.substring(0, path.length - 1)
        : path;
    final target = requestTarget ??
        (queryPairs != null
            ? requestTargetFromPairs(path, queryPairs)
            : requestTargetFrom(path, query));

    switch (normalized) {
      case '/auth/bearer':
        return _bearer(headers);
      case '/auth/api-key':
        return _apiKey(headers, query);
      case '/auth/basic':
        return _basic(headers);
      case '/auth/digest':
        return _digest(method, target, headers);
      case '/auth/hmac':
        // Bind HMAC to path + ordered query + body. Routing still uses
        // [normalized]; the signed path must match what the client sent.
        final queryString = queryPairs != null
            ? encodeQueryPairs(queryPairs)
            : encodeQueryPairs([
                for (final e in query.entries) (name: e.key, value: e.value),
              ]);
        return _hmac(
          method,
          path,
          headers,
          queryString: queryString,
          body: body ?? '',
        );
      case '/auth/rate-limited':
        return const MockAuthResult(
          statusCode: 429,
          headers: {'retry-after': '1'},
          body: {
            'ok': false,
            'error': 'rate_limited',
            'reason': 'too_many_requests',
          },
        );
      default:
        return null;
    }
  }

  MockAuthResult _bearer(Map<String, String> headers) {
    final raw = _header(headers, 'authorization');
    if (raw == null || raw.isEmpty) {
      return _unauthorized(
        reason: 'missing_authorization',
        wwwAuthenticate: 'Bearer realm="mock"',
      );
    }
    final parts = raw.split(RegExp(r'\s+'));
    if (parts.length != 2 || parts[0].toLowerCase() != 'bearer') {
      return _unauthorized(
        reason: 'malformed_authorization',
        wwwAuthenticate: 'Bearer realm="mock"',
      );
    }
    final token = parts[1];
    if (token == MockAuthDemo.bearerExpiredToken) {
      return _unauthorized(
        reason: 'expired',
        wwwAuthenticate: 'Bearer realm="mock", error="invalid_token"',
      );
    }
    if (token == MockAuthDemo.bearerWrongAudienceToken) {
      return const MockAuthResult(
        statusCode: 403,
        body: {
          'ok': false,
          'error': 'forbidden',
          'reason': 'wrong_audience',
          'expectedAudience': MockAuthDemo.bearerAudience,
        },
      );
    }
    if (token != MockAuthDemo.bearerToken) {
      return _unauthorized(
        reason: 'invalid_token',
        wwwAuthenticate: 'Bearer realm="mock", error="invalid_token"',
      );
    }
    return const MockAuthResult(
      statusCode: 200,
      body: {
        'ok': true,
        'scheme': 'bearer',
        'audience': MockAuthDemo.bearerAudience,
      },
    );
  }

  MockAuthResult _apiKey(
    Map<String, String> headers,
    Map<String, String> query,
  ) {
    final fromHeader = _header(headers, MockAuthDemo.apiKeyHeader);
    final fromQuery = query[MockAuthDemo.apiKeyQuery];
    final key = (fromHeader != null && fromHeader.isNotEmpty)
        ? fromHeader
        : fromQuery;
    if (key == null || key.isEmpty) {
      return const MockAuthResult(
        statusCode: 401,
        body: {
          'ok': false,
          'error': 'unauthorized',
          'reason': 'missing_api_key',
        },
      );
    }
    if (key != MockAuthDemo.apiKey) {
      return const MockAuthResult(
        statusCode: 403,
        body: {
          'ok': false,
          'error': 'forbidden',
          'reason': 'invalid_api_key',
        },
      );
    }
    return MockAuthResult(
      statusCode: 200,
      body: {
        'ok': true,
        'scheme': 'api_key',
        'via': fromHeader != null && fromHeader.isNotEmpty ? 'header' : 'query',
      },
    );
  }

  MockAuthResult _basic(Map<String, String> headers) {
    final challenge =
        'Basic realm="${MockAuthDemo.basicRealm}", charset="UTF-8"';
    final raw = _header(headers, 'authorization');
    if (raw == null || raw.isEmpty) {
      return _unauthorized(
        reason: 'missing_authorization',
        wwwAuthenticate: challenge,
      );
    }
    final parts = raw.split(RegExp(r'\s+'));
    if (parts.length != 2 || parts[0].toLowerCase() != 'basic') {
      return _unauthorized(
        reason: 'malformed_authorization',
        wwwAuthenticate: challenge,
      );
    }
    try {
      final decoded = utf8.decode(base64Decode(parts[1]));
      final colon = decoded.indexOf(':');
      if (colon <= 0) {
        return _unauthorized(
          reason: 'malformed_authorization',
          wwwAuthenticate: challenge,
        );
      }
      final user = decoded.substring(0, colon);
      final password = decoded.substring(colon + 1);
      if (user != MockAuthDemo.basicUser ||
          password != MockAuthDemo.basicPassword) {
        return _unauthorized(
          reason: 'invalid_credentials',
          wwwAuthenticate: challenge,
        );
      }
      return const MockAuthResult(
        statusCode: 200,
        body: {'ok': true, 'scheme': 'basic', 'user': MockAuthDemo.basicUser},
      );
    } on FormatException {
      return _unauthorized(
        reason: 'malformed_authorization',
        wwwAuthenticate: challenge,
      );
    }
  }

  MockAuthResult _digest(
    String method,
    String requestTarget,
    Map<String, String> headers,
  ) {
    final challenge = 'Digest realm="${MockAuthDemo.digestRealm}", '
        'qop="auth", nonce="${MockAuthDemo.digestNonce}", '
        'opaque="${MockAuthDemo.digestOpaque}", algorithm=MD5';
    final raw = _header(headers, 'authorization');
    if (raw == null || raw.isEmpty) {
      return _unauthorized(
        reason: 'missing_authorization',
        wwwAuthenticate: challenge,
      );
    }
    if (!raw.toLowerCase().startsWith('digest ')) {
      return _unauthorized(
        reason: 'malformed_authorization',
        wwwAuthenticate: challenge,
      );
    }
    final params = _parseDigestParams(raw.substring(7));
    final username = params['username'];
    final realm = params['realm'];
    final nonce = params['nonce'];
    final uri = params['uri'];
    final response = params['response'];
    final qop = params['qop'];
    final nc = params['nc'];
    final cnonce = params['cnonce'];
    final algorithm = params['algorithm'];
    final opaque = params['opaque'];
    if (username == null ||
        realm == null ||
        nonce == null ||
        uri == null ||
        response == null) {
      return _unauthorized(
        reason: 'malformed_authorization',
        wwwAuthenticate: challenge,
      );
    }

    // Require qop=auth with non-empty nc and cnonce — the challenge advertises
    // qop="auth" so the legacy no-qop path is not accepted.
    if (qop != 'auth' || nc == null || nc.isEmpty || cnonce == null || cnonce.isEmpty) {
      return _unauthorized(
        reason: 'missing_qop_params',
        wwwAuthenticate: challenge,
      );
    }

    // Claimed uri must match the actual request-target; HA2 uses the verified
    // value (path + optional query), not a client-asserted URI.
    if (uri != requestTarget) {
      return _unauthorized(
        reason: 'uri_mismatch',
        wwwAuthenticate: challenge,
      );
    }
    if (algorithm != null && algorithm.toUpperCase() != 'MD5') {
      return _unauthorized(
        reason: 'unsupported_algorithm',
        wwwAuthenticate: challenge,
      );
    }
    // Opaque is advertised in the challenge; require an exact echo.
    if (opaque != MockAuthDemo.digestOpaque) {
      return _unauthorized(
        reason: 'invalid_opaque',
        wwwAuthenticate: challenge,
      );
    }
    if (username != MockAuthDemo.basicUser ||
        realm != MockAuthDemo.digestRealm ||
        nonce != MockAuthDemo.digestNonce) {
      return _unauthorized(
        reason: 'invalid_credentials',
        wwwAuthenticate: challenge,
      );
    }

    // nc must be exactly 8 hex digits (RFC 7616) before response/replay checks.
    final ncValue = DigestNc.tryParse(nc);
    if (ncValue == null || ncValue < 1) {
      return _unauthorized(
        reason: 'invalid_nc',
        wwwAuthenticate: challenge,
      );
    }

    final ha1 = _md5Hex(
      '$username:$realm:${MockAuthDemo.basicPassword}',
    );
    final ha2 = _md5Hex('$method:$requestTarget');
    final expected = _md5Hex('$ha1:$nonce:$nc:$cnonce:$qop:$ha2');
    if (response.toLowerCase() != expected) {
      return _unauthorized(
        reason: 'invalid_credentials',
        wwwAuthenticate: challenge,
      );
    }

    // Replay protection: reject duplicate or non-monotonic nc for the same
    // nonce+cnonce tuple. MD5 Digest remains fixture-only.
    final clientKey = '$nonce|$cnonce';
    final previous = _digestNcByClient[clientKey];
    if (previous != null && ncValue <= previous) {
      return _unauthorized(
        reason: 'digest_replay',
        wwwAuthenticate: challenge,
      );
    }
    _digestNcByClient[clientKey] = ncValue;

    return const MockAuthResult(
      statusCode: 200,
      body: {
        'ok': true,
        'scheme': 'digest',
        'user': MockAuthDemo.basicUser,
      },
    );
  }

  MockAuthResult _hmac(
    String method,
    String path,
    Map<String, String> headers, {
    required String queryString,
    required String body,
  }) {
    final keyId = _header(headers, 'x-key-id');
    final timestampRaw = _header(headers, 'x-timestamp');
    final nonce = _header(headers, 'x-nonce');
    final signature = _header(headers, 'x-signature');

    if (keyId == null ||
        keyId.isEmpty ||
        timestampRaw == null ||
        timestampRaw.isEmpty ||
        nonce == null ||
        nonce.isEmpty ||
        signature == null ||
        signature.isEmpty) {
      return const MockAuthResult(
        statusCode: 401,
        body: {
          'ok': false,
          'error': 'unauthorized',
          'reason': 'missing_hmac_headers',
          'required': ['X-Key-Id', 'X-Timestamp', 'X-Nonce', 'X-Signature'],
        },
      );
    }
    if (keyId != MockAuthDemo.hmacKeyId) {
      return const MockAuthResult(
        statusCode: 403,
        body: {
          'ok': false,
          'error': 'forbidden',
          'reason': 'unknown_key_id',
        },
      );
    }
    final timestamp = int.tryParse(timestampRaw);
    if (timestamp == null) {
      return const MockAuthResult(
        statusCode: 401,
        body: {
          'ok': false,
          'error': 'unauthorized',
          'reason': 'malformed_timestamp',
        },
      );
    }
    final nowSec = _clock().toUtc().millisecondsSinceEpoch ~/ 1000;
    final skew = (nowSec - timestamp).abs();
    if (skew > MockAuthDemo.hmacMaxSkew.inSeconds) {
      return const MockAuthResult(
        statusCode: 401,
        body: {
          'ok': false,
          'error': 'unauthorized',
          'reason': 'timestamp_skew',
        },
      );
    }
    if (_seenNonces.contains(nonce)) {
      return const MockAuthResult(
        statusCode: 401,
        body: {
          'ok': false,
          'error': 'unauthorized',
          'reason': 'replay',
        },
      );
    }
    final expected = hmacSignature(
      method: method,
      path: path,
      queryString: queryString,
      body: body,
      timestamp: timestampRaw,
      nonce: nonce,
    );
    if (signature.toLowerCase() != expected) {
      return const MockAuthResult(
        statusCode: 401,
        body: {
          'ok': false,
          'error': 'unauthorized',
          'reason': 'invalid_signature',
        },
      );
    }
    _seenNonces.add(nonce);
    return const MockAuthResult(
      statusCode: 200,
      body: {
        'ok': true,
        'scheme': 'hmac',
        'keyId': MockAuthDemo.hmacKeyId,
      },
    );
  }

  /// Canonical HMAC-SHA256 hex digest for the mock contract.
  ///
  /// Payload: `METHOD\npath\nqueryString\nbody\ntimestamp\nnonce`.
  static String hmacSignature({
    required String method,
    required String path,
    required String timestamp,
    required String nonce,
    String queryString = '',
    String body = '',
    String secret = MockAuthDemo.hmacSecret,
  }) {
    final payload =
        '${method.toUpperCase()}\n$path\n$queryString\n$body\n$timestamp\n$nonce';
    final digest =
        Hmac(sha256, utf8.encode(secret)).convert(utf8.encode(payload));
    return digest.toString();
  }

  /// Builds an HTTP request-target from ordered query pairs.
  static String requestTargetFromPairs(
    String path,
    List<({String name, String value})> pairs,
  ) {
    final encoded = encodeQueryPairs(pairs);
    return encoded.isEmpty ? path : '$path?$encoded';
  }

  static String encodeQueryPairs(List<({String name, String value})> pairs) {
    if (pairs.isEmpty) return '';
    return pairs
        .map(
          (p) =>
              '${Uri.encodeQueryComponent(p.name)}=${Uri.encodeQueryComponent(p.value)}',
        )
        .join('&');
  }

  /// Builds an HTTP request-target (`path` or `path?query`) for Digest binding.
  static String requestTargetFrom(String path, Map<String, String> query) {
    if (query.isEmpty) return path;
    final encoded = query.entries
        .map(
          (e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');
    return '$path?$encoded';
  }

  /// Computes the `response` field for a Digest `qop=auth` request.
  ///
  /// Both [nc] and [cnonce] are required because the endpoint no longer
  /// accepts the legacy no-qop path.
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
    final ha1 = _md5Hex('$username:$realm:$password');
    final ha2 = _md5Hex('$method:$uri');
    return _md5Hex('$ha1:$nonce:$nc:$cnonce:$qop:$ha2');
  }

  static MockAuthResult _unauthorized({
    required String reason,
    required String wwwAuthenticate,
  }) {
    return MockAuthResult(
      statusCode: 401,
      headers: {'www-authenticate': wwwAuthenticate},
      body: {
        'ok': false,
        'error': 'unauthorized',
        'reason': reason,
      },
    );
  }

  static String? _header(Map<String, String> headers, String name) {
    final wanted = name.toLowerCase();
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == wanted) return entry.value;
    }
    return null;
  }

  static Map<String, String> _parseDigestParams(String raw) {
    final out = <String, String>{};
    final pattern = RegExp(r'(\w+)=(?:"([^"]*)"|([^\s,]+))');
    for (final match in pattern.allMatches(raw)) {
      final key = match.group(1)!;
      final value = match.group(2) ?? match.group(3) ?? '';
      out[key] = value;
    }
    return out;
  }

  static String _md5Hex(String input) => md5.convert(utf8.encode(input)).toString();
}
