import 'dart:async';
import 'dart:convert';

import 'curl_runtime_transport_stub.dart'
    if (dart.library.js_interop) 'curl_runtime_transport_web.dart';
import 'curl_import_legacy.dart'
    if (dart.library.js_interop) 'curl_import_web.dart' as legacy;
import 'curl_import_result.dart';
import 'request_draft.dart';
import 'request_draft_codec.dart';
import 'request_field.dart';

const usePythonCurlRuntime = bool.fromEnvironment('CURL_PYTHON_RUNTIME');

/// Python-enabled Web builds do not link the legacy Dart parser.
///
/// Native/static compatibility builds keep the legacy implementation until
/// their runtime/packaging boundary is replaced and measured.
Future<CurlImportResult> importCurlText(
  String raw, {
  required String Function() newId,
}) async {
  if (!usePythonCurlRuntime) return legacy.importLegacyCurl(raw, newId: newId);
  return importPythonCurl(raw, newId: newId);
}

/// Transfer/shape boundary only: no curl lexing or request processing in Dart.
Future<CurlImportResult> importPythonCurl(
  String raw, {
  required String Function() newId,
  Future<String> Function(String)? transport,
  Duration timeout = const Duration(seconds: 6),
}) async {
  try {
    if (utf8.encode(raw).length > 65536) {
      return _failure('inputTooLarge');
    }
    final text = await (transport ?? postCurlToPython)(raw).timeout(timeout);
    return decodePythonCurlReply(text, newId: newId);
  } on TimeoutException {
    return _failure('runtimeTimeout');
  } on FormatException {
    return _failure('runtimeResponse');
  } catch (_) {
    // A failed/unavailable runtime is not permission to invoke the old parser.
    return _failure('runtimeUnavailable');
  }
}

CurlImportResult _failure(String code) => CurlImportResult(
      errors: [RequestDraftIssue('httpDraft.curl.error.$code')],
    );

CurlImportResult decodePythonCurlReply(
  String text, {
  required String Function() newId,
}) {
  if (text.length > 1048576) throw const FormatException('runtimeResponse');
  final envelope = jsonDecode(text);
  if (envelope is! Map || envelope['schema'] != 'curl-runtime/1') {
    throw const FormatException('runtimeResponse');
  }
  final result = envelope['result'];
  if (result is! Map || result['ok'] is! bool) {
    throw const FormatException('runtimeResponse');
  }
  List<RequestDraftIssue> issues(Object? value, String kind) {
    if (value is! List || value.length > 4096) {
      throw const FormatException('runtimeResponse');
    }
    return [
      for (final code in value)
        if (code is String && code.length < 128 &&
            code.startsWith('httpDraft.curl.$kind.'))
          RequestDraftIssue(code)
        else
          throw const FormatException('runtimeResponse'),
    ];
  }
  final errors = issues(result['errors'], 'error');
  final warnings = issues(result['warnings'], 'warn');
  if (result['ok'] == false) {
    if (result['draft'] != null || errors.isEmpty) {
      throw const FormatException('runtimeResponse');
    }
    return CurlImportResult(errors: errors, warnings: warnings);
  }
  final data = result['draft'];
  if (data is! Map || errors.isNotEmpty || data['method'] is! String ||
      data['url'] is! String || data['rawBody'] is! String) {
    throw const FormatException('runtimeResponse');
  }
  final method = HttpMethodX.tryParse(data['method'] as String);
  final modes = {for (final mode in RequestBodyMode.values) mode.name: mode};
  final mode = modes[data['bodyMode']];
  if (method == null || mode == null || mode == RequestBodyMode.multipart) {
    throw const FormatException('runtimeResponse');
  }
  List<RequestField> rows(Object? value) {
    if (value is! List || value.length > 4096) {
      throw const FormatException('runtimeResponse');
    }
    final out = <RequestField>[];
    for (final row in value) {
      if (row is! Map || row['name'] is! String || row['value'] is! String ||
          row['sensitive'] is! bool) {
        throw const FormatException('runtimeResponse');
      }
      out.add(RequestField(id: newId(), name: row['name'] as String,
          value: row['value'] as String, sensitive: row['sensitive'] as bool));
    }
    return out.isEmpty ? [RequestField(id: newId())] : out;
  }
  final draft = RequestDraft(method: method, url: data['url'] as String,
      rawBody: data['rawBody'] as String, bodyMode: mode,
      query: rows(data['query']), headers: rows(data['headers']),
      formFields: rows(data['formFields']));
  return CurlImportResult(draft: draft,
      warnings: [...warnings, ...RequestDraftValidator.validate(draft)]);
}
