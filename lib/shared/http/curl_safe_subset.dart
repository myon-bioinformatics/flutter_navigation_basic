import 'dart:convert';

import '../../core/utils/ascii_fullwidth.dart';
import 'request_draft.dart';
import 'request_draft_codec.dart';
import 'request_field.dart';

/// Outcome of a safe-subset curl import (no shell execution, no file I/O).
class CurlImportResult {
  const CurlImportResult({
    this.draft,
    this.errors = const <RequestDraftIssue>[],
    this.warnings = const <RequestDraftIssue>[],
  });

  final RequestDraft? draft;
  final List<RequestDraftIssue> errors;
  final List<RequestDraftIssue> warnings;

  bool get isOk => draft != null && errors.isEmpty;
}

/// Parses / emits a **safe subset** of curl for [RequestDraft] round-trips.
///
/// Supported: `-X/--request`, URL / `--url`, `-H/--header`,
/// `-d/--data/--data-raw/--data-binary/--data-urlencode`, `-G/--get`,
/// `-u/--user` (→ Basic Authorization, sensitive), `-A/--user-agent`,
/// `-e/--referer`, `-I/--head`, ignored-with-warning `-L/--location`.
///
/// Rejected: shell metacharacters / command substitution, `@file` bodies,
/// `--config` / proxy / cert / unix-socket / output redirects, and other
/// flags outside the subset.
class CurlSafeSubset {
  const CurlSafeSubset._();

  static final _forbiddenMeta = RegExp(r'''[`$]|\$\(|\$\{|[|;<>]''');

  /// Display-only flags that never change RequestDraft semantics.
  /// Everything else outside the explicit handlers fails closed.
  static const _displayOnlyLongFlags = <String>{
    'silent',
    'show-error',
    'include',
    'verbose',
    'insecure',
    'location',
  };

  static const _displayOnlyShortFlags = <String>{
    '-s',
    '-S',
    '-i',
    '-v',
    '-k',
    '-L',
  };

  static CurlImportResult tryParse(
    String raw, {
    String Function()? newId,
  }) {
    final id = newId ?? _defaultId;
    final normalized = normalizeAsciiFullwidth(raw).trim();
    if (normalized.isEmpty) {
      return const CurlImportResult(
        errors: [RequestDraftIssue('httpDraft.curl.error.empty')],
      );
    }

    if (_forbiddenMeta.hasMatch(_stripQuotedRegions(normalized))) {
      return const CurlImportResult(
        errors: [RequestDraftIssue('httpDraft.curl.error.shellMeta')],
      );
    }

    final flattened = _flattenContinuations(normalized);
    final tokens = _tokenize(flattened);
    if (tokens == null) {
      return const CurlImportResult(
        errors: [RequestDraftIssue('httpDraft.curl.error.unbalancedQuotes')],
      );
    }
    if (tokens.isEmpty) {
      return const CurlImportResult(
        errors: [RequestDraftIssue('httpDraft.curl.error.empty')],
      );
    }

    var index = 0;
    if (tokens[index].toLowerCase() == 'curl') {
      index++;
    } else {
      return const CurlImportResult(
        errors: [RequestDraftIssue('httpDraft.curl.error.notCurl')],
      );
    }

    HttpMethod method = HttpMethod.get;
    var methodSet = false;
    String? url;
    final headers = <RequestField>[];
    final dataChunks = <String>[];
    final urlEncodeFields = <RequestField>[];
    var useGetWithData = false;
    final warnings = <RequestDraftIssue>[];
    final errors = <RequestDraftIssue>[];

    while (index < tokens.length) {
      final token = tokens[index];
      index++;

      if (token == '-X' || token == '--request') {
        final value = _needArg(tokens, index, errors, token);
        if (value == null) break;
        index++;
        final parsed = HttpMethodX.tryParse(value);
        if (parsed == null) {
          errors.add(
            RequestDraftIssue(
              'httpDraft.curl.error.badMethod',
              argument: value,
            ),
          );
        } else {
          method = parsed;
          methodSet = true;
        }
        continue;
      }

      if (token == '--url') {
        final value = _needArg(tokens, index, errors, token);
        if (value == null) break;
        index++;
        url = value;
        continue;
      }

      if (token == '-H' || token == '--header') {
        final value = _needArg(tokens, index, errors, token);
        if (value == null) break;
        index++;
        final header = _parseHeader(value, id);
        if (header == null) {
          errors.add(
            const RequestDraftIssue('httpDraft.curl.error.badHeader'),
          );
        } else {
          headers.add(header);
        }
        continue;
      }

      if (token == '-d' ||
          token == '--data' ||
          token == '--data-raw' ||
          token == '--data-binary') {
        final value = _needArg(tokens, index, errors, token);
        if (value == null) break;
        index++;
        if (value.startsWith('@')) {
          errors.add(
            const RequestDraftIssue('httpDraft.curl.error.fileBody'),
          );
          continue;
        }
        dataChunks.add(value);
        continue;
      }

      if (token == '--data-urlencode') {
        final value = _needArg(tokens, index, errors, token);
        if (value == null) break;
        index++;
        if (_isDataUrlEncodeFileForm(value)) {
          errors.add(
            const RequestDraftIssue('httpDraft.curl.error.fileBody'),
          );
          continue;
        }
        final eq = value.indexOf('=');
        if (eq < 0) {
          urlEncodeFields.add(
            RequestField(id: id(), name: value, value: ''),
          );
        } else if (eq == 0) {
          urlEncodeFields.add(
            RequestField(id: id(), name: '', value: value.substring(1)),
          );
        } else {
          urlEncodeFields.add(
            RequestField(
              id: id(),
              name: value.substring(0, eq),
              value: value.substring(eq + 1),
            ),
          );
        }
        continue;
      }

      if (token == '-u' || token == '--user') {
        final value = _needArg(tokens, index, errors, token);
        if (value == null) break;
        index++;
        headers.add(_basicAuthHeader(value, id));
        warnings.add(
          const RequestDraftIssue('httpDraft.curl.warn.basicAuthMapped'),
        );
        continue;
      }

      if (token == '-A' || token == '--user-agent') {
        final value = _needArg(tokens, index, errors, token);
        if (value == null) break;
        index++;
        headers.add(RequestField(id: id(), name: 'User-Agent', value: value));
        continue;
      }

      if (token == '-e' || token == '--referer') {
        final value = _needArg(tokens, index, errors, token);
        if (value == null) break;
        index++;
        headers.add(RequestField(id: id(), name: 'Referer', value: value));
        continue;
      }

      if (token == '-G' || token == '--get') {
        useGetWithData = true;
        continue;
      }

      if (token == '-I' || token == '--head') {
        method = HttpMethod.head;
        methodSet = true;
        continue;
      }

      if (token == '-L' || token == '--location') {
        warnings.add(
          const RequestDraftIssue('httpDraft.curl.warn.ignoredRedirect'),
        );
        continue;
      }

      if (_displayOnlyShortFlags.contains(token) ||
          (token.startsWith('--') &&
              _displayOnlyLongFlags
                  .contains(token.substring(2).split('=').first))) {
        warnings.add(
          RequestDraftIssue(
            'httpDraft.curl.warn.ignoredFlag',
            argument: token,
          ),
        );
        continue;
      }

      if (token.startsWith('--')) {
        // Fail closed: do not consume a following positional token.
        errors.add(
          RequestDraftIssue(
            'httpDraft.curl.error.unsupportedFlag',
            argument: token,
          ),
        );
        continue;
      }

      if (token.startsWith('-') && token.length > 1) {
        errors.add(
          RequestDraftIssue(
            'httpDraft.curl.error.unsupportedFlag',
            argument: token,
          ),
        );
        continue;
      }

      // Positional URL
      if (url != null) {
        errors.add(
          RequestDraftIssue(
            'httpDraft.curl.error.extraPositional',
            argument: token,
          ),
        );
      } else {
        url = token;
      }
    }

    if (errors.isNotEmpty) {
      return CurlImportResult(errors: errors, warnings: warnings);
    }
    if (url == null || url.trim().isEmpty) {
      return CurlImportResult(
        errors: const [RequestDraftIssue('httpDraft.curl.error.urlRequired')],
        warnings: warnings,
      );
    }

    var bodyMode = RequestBodyMode.none;
    var rawBody = '';
    var formFields = <RequestField>[];
    var query = <RequestField>[];

    if (urlEncodeFields.isNotEmpty) {
      if (useGetWithData) {
        query = urlEncodeFields;
      } else {
        bodyMode = RequestBodyMode.formUrlEncoded;
        formFields = urlEncodeFields;
        if (!methodSet) method = HttpMethod.post;
      }
    } else if (dataChunks.isNotEmpty) {
      final joined = dataChunks.join('&');
      if (useGetWithData) {
        query = _queryFromData(joined, id);
      } else {
        if (!methodSet) method = HttpMethod.post;
        String? contentType;
        for (final header in headers) {
          if (header.normalizedName == 'content-type') {
            contentType = header.normalizedValue.toLowerCase();
            break;
          }
        }
        if (contentType != null && contentType.contains('application/json')) {
          bodyMode = RequestBodyMode.json;
          rawBody = dataChunks.length == 1 ? dataChunks.first : joined;
        } else if (contentType != null &&
            contentType.contains('application/x-www-form-urlencoded')) {
          bodyMode = RequestBodyMode.formUrlEncoded;
          formFields = _queryFromData(joined, id);
        } else if (_looksLikeJson(joined)) {
          bodyMode = RequestBodyMode.json;
          rawBody = dataChunks.length == 1 ? dataChunks.first : joined;
        } else if (joined.contains('=') && !joined.trimLeft().startsWith('{')) {
          bodyMode = RequestBodyMode.formUrlEncoded;
          formFields = _queryFromData(joined, id);
        } else {
          bodyMode = RequestBodyMode.raw;
          rawBody = dataChunks.length == 1 ? dataChunks.first : joined;
        }
      }
    }

    // Ensure at least one empty row for editors.
    if (query.isEmpty) query = [RequestField(id: id())];
    if (headers.isEmpty) headers.add(RequestField(id: id()));
    if (formFields.isEmpty) formFields = [RequestField(id: id())];

    final draft = RequestDraft(
      method: method,
      url: url.trim(),
      query: query,
      headers: headers,
      bodyMode: bodyMode,
      rawBody: rawBody,
      formFields: formFields,
    );

    // Surface draft validation as import warnings (non-fatal for paste UX).
    for (final issue in RequestDraftValidator.validate(draft)) {
      warnings.add(issue);
    }

    return CurlImportResult(draft: draft, warnings: warnings);
  }

  /// Export uses the shared codec; secrets redacted by default.
  static String export(
    RequestDraft draft, {
    bool redactSecrets = true,
  }) =>
      RequestDraftCodec.toCurl(draft, redactSecrets: redactSecrets);

  static var _seq = 0;
  static String _defaultId() => 'c${_seq++}';

  static String? _needArg(
    List<String> tokens,
    int index,
    List<RequestDraftIssue> errors,
    String flag,
  ) {
    if (index >= tokens.length) {
      errors.add(
        RequestDraftIssue('httpDraft.curl.error.missingArg', argument: flag),
      );
      return null;
    }
    return tokens[index];
  }

  static RequestField? _parseHeader(String raw, String Function() id) {
    final trimmed = raw.trim();
    final colon = trimmed.indexOf(':');
    if (colon <= 0) return null;
    final name = trimmed.substring(0, colon).trim();
    final value = trimmed.substring(colon + 1).trim();
    if (name.contains('\r') ||
        name.contains('\n') ||
        value.contains('\r') ||
        value.contains('\n')) {
      return null;
    }
    final sensitive = RequestDraftCodec.isSensitiveHeaderName(name) ||
        value == '***' ||
        value.contains('***');
    return RequestField(
      id: id(),
      name: name,
      value: value,
      sensitive: sensitive,
    );
  }

  static RequestField _basicAuthHeader(String userPass, String Function() id) {
    final encoded = base64Encode(utf8.encode(userPass));
    return RequestField(
      id: id(),
      name: 'Authorization',
      value: 'Basic $encoded',
      sensitive: true,
    );
  }

  static List<RequestField> _queryFromData(String raw, String Function() id) {
    if (raw.isEmpty) return [RequestField(id: id())];
    final fields = <RequestField>[];
    for (final part in raw.split('&')) {
      if (part.isEmpty) continue;
      final eq = part.indexOf('=');
      if (eq < 0) {
        fields.add(
          RequestField(
            id: id(),
            name: Uri.decodeQueryComponent(part),
            value: '',
          ),
        );
      } else {
        fields.add(
          RequestField(
            id: id(),
            name: Uri.decodeQueryComponent(part.substring(0, eq)),
            value: Uri.decodeQueryComponent(part.substring(eq + 1)),
          ),
        );
      }
    }
    return fields.isEmpty ? [RequestField(id: id())] : fields;
  }

  static bool _isDataUrlEncodeFileForm(String value) {
    if (value.startsWith('@')) return true;
    final at = value.indexOf('@');
    if (at < 0) return false;
    final eq = value.indexOf('=');
    // curl `name@filename` has '@' with no '=' before it.
    return eq < 0 || at < eq;
  }

  static bool _looksLikeJson(String raw) {
    final t = raw.trimLeft();
    return t.startsWith('{') || t.startsWith('[');
  }

  static String _flattenContinuations(String input) {
    return input.replaceAll(RegExp(r'\\\r?\n'), ' ');
  }

  /// Remove quoted spans so meta checks ignore literals.
  static String _stripQuotedRegions(String input) {
    final buffer = StringBuffer();
    var i = 0;
    while (i < input.length) {
      final c = input[i];
      if (c == "'" || c == '"') {
        final quote = c;
        i++;
        while (i < input.length && input[i] != quote) {
          if (quote == '"' && input[i] == '\\' && i + 1 < input.length) {
            i += 2;
            continue;
          }
          i++;
        }
        if (i < input.length) i++;
        buffer.write(' ');
        continue;
      }
      buffer.write(c);
      i++;
    }
    return buffer.toString();
  }

  static List<String>? _tokenize(String input) {
    final tokens = <String>[];
    final buffer = StringBuffer();
    var i = 0;
    var inSingle = false;
    var inDouble = false;
    // True once a quote pair has opened for the current token, so `''` / `""`
    // still emit an empty argument instead of vanishing.
    var sawQuoted = false;

    void flush() {
      if (buffer.isEmpty && !sawQuoted) return;
      tokens.add(buffer.toString());
      buffer.clear();
      sawQuoted = false;
    }

    while (i < input.length) {
      final c = input[i];
      if (inSingle) {
        if (c == "'") {
          inSingle = false;
        } else {
          buffer.write(c);
        }
        i++;
        continue;
      }
      if (inDouble) {
        if (c == '"') {
          inDouble = false;
        } else if (c == '\\' && i + 1 < input.length) {
          final next = input[i + 1];
          // Bash-like: only $, `, ", \, newline are special after backslash.
          if (next == r'$' ||
              next == '`' ||
              next == '"' ||
              next == '\\' ||
              next == '\n') {
            buffer.write(next);
          } else {
            buffer.write('\\');
            buffer.write(next);
          }
          i += 2;
          continue;
        } else {
          buffer.write(c);
        }
        i++;
        continue;
      }

      if (c == "'") {
        inSingle = true;
        sawQuoted = true;
        i++;
        continue;
      }
      if (c == '"') {
        inDouble = true;
        sawQuoted = true;
        i++;
        continue;
      }
      if (c == ' ' || c == '\t' || c == '\n' || c == '\r') {
        flush();
        i++;
        continue;
      }
      buffer.write(c);
      i++;
    }
    if (inSingle || inDouble) return null;
    flush();
    return tokens;
  }
}
