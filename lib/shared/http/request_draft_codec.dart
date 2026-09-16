import 'dart:convert';

import '../../core/utils/ascii_fullwidth.dart';
import 'request_draft.dart';
import 'request_field.dart';

class RequestDraftIssue {
  const RequestDraftIssue(this.code, {this.argument});

  final String code;
  final String? argument;
}

/// Pure validation for [RequestDraft] (no Flutter).
class RequestDraftValidator {
  const RequestDraftValidator._();

  static List<RequestDraftIssue> validate(RequestDraft draft) {
    final issues = <RequestDraftIssue>[];
    final url = draft.normalizedUrl;
    if (url.isEmpty) {
      issues.add(const RequestDraftIssue('httpDraft.error.urlRequired'));
    } else {
      final uri = Uri.tryParse(url);
      if (uri == null || !(uri.hasScheme && uri.host.isNotEmpty)) {
        issues.add(const RequestDraftIssue('httpDraft.error.urlInvalid'));
      }
    }

    for (final name in draft.duplicateHeaderNames) {
      issues.add(
        RequestDraftIssue('httpDraft.error.duplicateHeader', argument: name),
      );
    }
    if (draft.hasHeaderCrLf) {
      issues.add(const RequestDraftIssue('httpDraft.error.headerCrLf'));
    }

    if (draft.bodyMode == RequestBodyMode.json) {
      final raw = normalizeAsciiFullwidth(draft.rawBody).trim();
      if (raw.isNotEmpty) {
        try {
          jsonDecode(raw);
        } on FormatException {
          issues.add(const RequestDraftIssue('httpDraft.error.jsonInvalid'));
        }
      }
    }
    return issues;
  }
}

/// Builds URL / headers / body snapshots for preview and curl.
class RequestDraftCodec {
  const RequestDraftCodec._();

  static const sensitiveHeaderNames = {
    'authorization',
    'proxy-authorization',
    'cookie',
    'set-cookie',
    'x-api-key',
    'api-key',
    'x-auth-token',
  };

  /// True when a header/query/form/fragment field name looks secret-bearing.
  static bool isSensitiveFieldName(String name) {
    final n = normalizeAsciiFullwidth(name).trim().toLowerCase();
    if (n.isEmpty) return false;
    if (sensitiveHeaderNames.contains(n)) return true;
    if (_sensitiveExactNames.contains(n)) return true;
    return n.contains('api-key') ||
        n.contains('api_key') ||
        n.contains('token') ||
        n.contains('secret') ||
        n.contains('password') ||
        n.contains('signature') ||
        n.contains('credential') ||
        n.endsWith('_key') ||
        n.endsWith('-key') ||
        n.contains('access_key') ||
        n.contains('access-key') ||
        n.contains('sharedaccesssignature');
  }

  static const _sensitiveExactNames = {
    'key',
    'token',
    'secret',
    'password',
    'sig',
    'signature',
    'access_token',
    'refresh_token',
    'id_token',
    'x-amz-signature',
    'x-amz-credential',
    'x-amz-security-token',
    'sas',
  };

  static bool isSensitiveHeaderName(String name) => isSensitiveFieldName(name);

  static bool isSensitiveQueryName(String name) => isSensitiveFieldName(name);

  /// Builds the request URI while preserving query order and duplicate keys.
  ///
  /// Base-URL query pairs are parsed from the raw `uri.query` string in
  /// appearance order (not via [Uri.queryParametersAll], which groups by key
  /// and can reorder interleaved duplicates). Draft query rows append after.
  ///
  /// When [redactSecrets] is true, sensitive query names (explicit flag or
  /// known secret-ish names), URL `userInfo`, and fragment secrets are
  /// replaced with `***`.
  static Uri? buildUri(
    RequestDraft draft, {
    bool redactSecrets = false,
  }) {
    final base = draft.normalizedUrl;
    if (base.isEmpty) return null;
    final uri = Uri.tryParse(base);
    if (uri == null) return null;

    final pairs = _orderedWireQueryPairsDetailed(draft);

    final encoded = pairs.map((pair) {
      final value = redactSecrets && pair.sensitive ? '***' : pair.value;
      return '${Uri.encodeQueryComponent(pair.name)}='
          '${Uri.encodeQueryComponent(value)}';
    }).join('&');

    var result = uri.replace(query: encoded.isEmpty ? null : encoded);
    if (redactSecrets && result.userInfo.isNotEmpty) {
      result = result.replace(userInfo: '***');
    }
    if (redactSecrets && result.hasFragment) {
      result = result.replace(fragment: _redactFragment(result.fragment));
    }
    return result;
  }

  /// Parses `a=1&b=2` style query text into decoded name/value pairs in order.
  ///
  /// Empty segments (`&&`) are skipped. A segment without `=` is treated as a
  /// key with an empty value (same as [Uri.queryParametersAll]).
  static List<({String name, String value})> parseQueryPairs(String query) {
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

  /// URL query pairs first (raw order), then enabled draft query rows.
  ///
  /// Shared by curl/URI build, mock dispatch, HMAC binding, and the local
  /// mock server so duplicate keys / order cannot drift by transport.
  static List<({String name, String value})> orderedWireQueryPairs(
    RequestDraft draft,
  ) {
    return [
      for (final pair in _orderedWireQueryPairsDetailed(draft))
        (name: pair.name, value: pair.value),
    ];
  }

  /// Same order as [orderedWireQueryPairs], with sensitivity for redaction.
  static List<({String name, String value, bool sensitive})>
      _orderedWireQueryPairsDetailed(RequestDraft draft) {
    final uri = Uri.tryParse(draft.normalizedUrl);
    return [
      if (uri != null)
        for (final pair in parseQueryPairs(uri.query))
          (
            name: pair.name,
            value: pair.value,
            sensitive: isSensitiveQueryName(pair.name),
          ),
      for (final field in draft.enabledQuery)
        (
          name: normalizeAsciiFullwidth(field.name).trim(),
          value: field.normalizedValue,
          sensitive: field.sensitive || isSensitiveQueryName(field.name),
        ),
    ];
  }

  /// Redacts OAuth/signed fragment payloads. Opaque fragments (no `=`) become
  /// `***` entirely; `key=value` fragments redact secret-ish keys in place.
  static String _redactFragment(String fragment) {
    if (fragment.isEmpty) return fragment;
    if (!fragment.contains('=')) return '***';

    return fragment.split('&').map((part) {
      final eq = part.indexOf('=');
      if (eq <= 0) {
        return isSensitiveFieldName(part) ? '***' : part;
      }
      final name = part.substring(0, eq);
      final value = part.substring(eq + 1);
      if (isSensitiveFieldName(Uri.decodeQueryComponent(name))) {
        return '$name=***';
      }
      return '$name=$value';
    }).join('&');
  }

  static Map<String, String> buildHeaders(
    RequestDraft draft, {
    required bool redactSecrets,
  }) {
    final headers = <String, String>{};
    for (final field in draft.enabledHeaders) {
      final name = normalizeAsciiFullwidth(field.name).trim();
      final value = field.normalizedValue;
      final sensitive =
          field.sensitive || isSensitiveHeaderName(name);
      headers[name] = redactSecrets && sensitive ? '***' : value;
    }

    switch (draft.bodyMode) {
      case RequestBodyMode.json:
        headers.putIfAbsent('Content-Type', () => 'application/json');
      case RequestBodyMode.formUrlEncoded:
        headers.putIfAbsent(
          'Content-Type',
          () => 'application/x-www-form-urlencoded',
        );
      case RequestBodyMode.multipart:
        headers.putIfAbsent(
          'Content-Type',
          () => 'multipart/form-data; boundary=----FlutterNavBoundary',
        );
      case RequestBodyMode.none:
      case RequestBodyMode.raw:
        break;
    }
    return headers;
  }

  static String? buildBody(
    RequestDraft draft, {
    required bool redactSecrets,
  }) {
    switch (draft.bodyMode) {
      case RequestBodyMode.none:
        return null;
      case RequestBodyMode.raw:
        return _redactRawOrJsonBody(
          normalizeAsciiFullwidth(draft.rawBody),
          redactSecrets: redactSecrets,
        );
      case RequestBodyMode.json:
        if (draft.enabledJsonFields.isNotEmpty &&
            normalizeAsciiFullwidth(draft.rawBody).trim().isEmpty) {
          return jsonEncode(
            _jsonFromFields(
              draft.enabledJsonFields,
              redactSecrets: redactSecrets,
            ),
          );
        }
        return _redactRawOrJsonBody(
          normalizeAsciiFullwidth(draft.rawBody),
          redactSecrets: redactSecrets,
        );
      case RequestBodyMode.formUrlEncoded:
        return draft.enabledFormFields
            .map((f) {
              final name = Uri.encodeQueryComponent(
                normalizeAsciiFullwidth(f.name).trim(),
              );
              final sensitive =
                  f.sensitive || isSensitiveFieldName(f.name);
              final value = Uri.encodeQueryComponent(
                redactSecrets && sensitive ? '***' : f.normalizedValue,
              );
              return '$name=$value';
            })
            .join('&');
      case RequestBodyMode.multipart:
        const boundary = '----FlutterNavBoundary';
        final chunks = <String>[];
        for (final field in draft.enabledFormFields) {
          final name = normalizeAsciiFullwidth(field.name).trim();
          final sensitive =
              field.sensitive || isSensitiveFieldName(name);
          final value = redactSecrets && sensitive
              ? '***'
              : field.normalizedValue;
          chunks.add(
            '--$boundary\r\n'
            'Content-Disposition: form-data; name="$name"\r\n\r\n'
            '$value\r\n',
          );
        }
        chunks.add('--$boundary--');
        return chunks.join();
    }
  }

 
  static Map<String, Object?> _jsonFromFields(
    List<JsonBodyField> fields, {
    bool redactSecrets = false,
  }) {
    final map = <String, Object?>{};
    for (final field in fields) {
      final name = normalizeAsciiFullwidth(field.name).trim();
      final raw = normalizeAsciiFullwidth(field.value);
      final sensitive =
          field.sensitive || isSensitiveFieldName(name);
      if (redactSecrets && sensitive) {
        map[name] = '***';
        continue;
      }
      map[name] = switch (field.type) {
        JsonFieldType.string => raw,
        JsonFieldType.number => num.tryParse(raw) ?? raw,
        JsonFieldType.boolean => raw.toLowerCase() == 'true',
        JsonFieldType.nullValue => null,
      };
    }
    return map;
  }

  /// Redacts parseable JSON by sensitive keys. Opaque raw bodies are omitted
  /// from shareable snapshots when [redactSecrets] is true.
  static String? _redactRawOrJsonBody(
    String raw, {
    required bool redactSecrets,
  }) {
    if (!redactSecrets) return raw;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return raw;
    try {
      final decoded = jsonDecode(trimmed);
      return jsonEncode(_redactJsonTree(decoded));
    } on FormatException {
      // Cannot safely scan opaque bodies for secrets — omit from shareable
      // curl/receipts by default.
      return '[omitted: opaque raw body]';
    }
  }

  static Object? _redactJsonTree(Object? value) {
    if (value is Map) {
      final out = <String, Object?>{};
      for (final entry in value.entries) {
        final key = entry.key.toString();
        if (isSensitiveFieldName(key)) {
          out[key] = '***';
        } else {
          out[key] = _redactJsonTree(entry.value);
        }
      }
      return out;
    }
    if (value is List) {
      return [for (final item in value) _redactJsonTree(item)];
    }
    return value;
  }


  /// Redacted curl by default. Pass [redactSecrets]: false only for explicit
  /// user-confirmed secret copy.
  static String toCurl(
    RequestDraft draft, {
    bool redactSecrets = true,
  }) {
    final uri = buildUri(draft, redactSecrets: redactSecrets);
    final url = uri?.toString() ?? draft.normalizedUrl;
    final parts = <String>['curl -X ${draft.method.label}'];
    if (url.isNotEmpty) {
      parts.add(_shellQuote(url));
    }
    final headers = buildHeaders(draft, redactSecrets: redactSecrets);
    for (final entry in headers.entries) {
      parts.add('-H ${_shellQuote('${entry.key}: ${entry.value}')}');
    }
    final body = buildBody(draft, redactSecrets: redactSecrets);
    final methodAllowsBody =
        draft.method != HttpMethod.get && draft.method != HttpMethod.head;
    if (methodAllowsBody && body != null && body.isNotEmpty) {
      parts.add('--data-binary ${_shellQuote(body)}');
    }
    return parts.join(' \\\n  ');
  }

  static String _shellQuote(String value) {
    if (value.isEmpty) return "''";
    return "'${value.replaceAll("'", "'\\''")}'";
  }
}
