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

  /// True when a header/query/form field name looks secret-bearing.
  static bool isSensitiveFieldName(String name) {
    final n = normalizeAsciiFullwidth(name).trim().toLowerCase();
    if (n.isEmpty) return false;
    if (sensitiveHeaderNames.contains(n)) return true;
    if (n == 'key' || n == 'token' || n == 'secret' || n == 'password') {
      return true;
    }
    return n.contains('api-key') ||
        n.contains('api_key') ||
        n.contains('token') ||
        n.contains('secret') ||
        n.contains('password') ||
        n.endsWith('_key') ||
        n.endsWith('-key') ||
        n.contains('access_key') ||
        n.contains('access-key');
  }

  static bool isSensitiveHeaderName(String name) => isSensitiveFieldName(name);

  static bool isSensitiveQueryName(String name) => isSensitiveFieldName(name);

  /// Builds the request URI while preserving query order and duplicate keys.
  ///
  /// When [redactSecrets] is true, sensitive query names (explicit flag or
  /// known secret-ish names) and URL `userInfo` are replaced with `***`.
  static Uri? buildUri(
    RequestDraft draft, {
    bool redactSecrets = false,
  }) {
    final base = draft.normalizedUrl;
    if (base.isEmpty) return null;
    final uri = Uri.tryParse(base);
    if (uri == null) return null;

    final pairs = <({String name, String value, bool sensitive})>[
      for (final entry in uri.queryParametersAll.entries)
        for (final value in entry.value)
          (
            name: entry.key,
            value: value,
            sensitive: isSensitiveQueryName(entry.key),
          ),
      for (final field in draft.enabledQuery)
        (
          name: normalizeAsciiFullwidth(field.name).trim(),
          value: field.normalizedValue,
          sensitive: field.sensitive || isSensitiveQueryName(field.name),
        ),
    ];

    final encoded = pairs.map((pair) {
      final value = redactSecrets && pair.sensitive ? '***' : pair.value;
      return '${Uri.encodeQueryComponent(pair.name)}='
          '${Uri.encodeQueryComponent(value)}';
    }).join('&');

    var result = uri.replace(query: encoded.isEmpty ? null : encoded);
    if (redactSecrets && result.userInfo.isNotEmpty) {
      result = result.replace(userInfo: '***');
    }
    return result;
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
        return normalizeAsciiFullwidth(draft.rawBody);
      case RequestBodyMode.json:
        if (draft.enabledJsonFields.isNotEmpty &&
            normalizeAsciiFullwidth(draft.rawBody).trim().isEmpty) {
          return jsonEncode(_jsonFromFields(draft.enabledJsonFields));
        }
        return normalizeAsciiFullwidth(draft.rawBody);
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

  static Map<String, Object?> _jsonFromFields(List<JsonBodyField> fields) {
    final map = <String, Object?>{};
    for (final field in fields) {
      final name = normalizeAsciiFullwidth(field.name).trim();
      final raw = normalizeAsciiFullwidth(field.value);
      map[name] = switch (field.type) {
        JsonFieldType.string => raw,
        JsonFieldType.number => num.tryParse(raw) ?? raw,
        JsonFieldType.boolean => raw.toLowerCase() == 'true',
        JsonFieldType.nullValue => null,
      };
    }
    return map;
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
    if (body != null && body.isNotEmpty) {
      parts.add('--data-binary ${_shellQuote(body)}');
    }
    return parts.join(' \\\n  ');
  }

  static String _shellQuote(String value) {
    if (value.isEmpty) return "''";
    return "'${value.replaceAll("'", "'\\''")}'";
  }
}
