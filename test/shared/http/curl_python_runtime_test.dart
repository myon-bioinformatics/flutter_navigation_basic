import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_application_1/shared/http/curl_import.dart';
import 'package:flutter_application_1/shared/http/request_field.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var sequence = 0;
  String newId() => 'runtime-test-${sequence++}';
  final fixture = jsonDecode(File('tool/python/fixtures/curl_request_cases.json')
      .readAsStringSync()) as Map<String, dynamic>;
  List<Map<String, Object>> rows(List<RequestField> values) => [
    for (final field in values)
      if (field.name.isNotEmpty || field.value.isNotEmpty)
        {'name': field.name, 'value': field.value, 'sensitive': field.sensitive},
  ];

  for (final item in fixture['cases'] as List) {
    test('Python reply maps to editor contract: ${item['id']}', () async {
      final expected = item['expected'] as Map<String, dynamic>;
      String? sent;
      final actual = await importPythonCurl(item['input'] as String, newId: newId,
          transport: (raw) async {
            sent = raw;
            return jsonEncode({'schema': 'curl-runtime/1', 'result': expected});
          });
      expect(sent, item['input']);
      expect(actual.isOk, expected['ok']);
      expect(actual.errors.map((e) => e.code), expected['errors']);
      expect(actual.warnings.where((e) => e.code.startsWith('httpDraft.curl.warn.'))
          .map((e) => e.code), expected['warnings']);
      final draft = actual.draft;
      if (draft != null) {
        expect({'method': draft.method.label, 'url': draft.url,
          'bodyMode': draft.bodyMode.name, 'rawBody': draft.rawBody,
          'headers': rows(draft.headers), 'query': rows(draft.query),
          'formFields': rows(draft.formFields)}, expected['draft']);
        final fields = [...draft.query, ...draft.headers, ...draft.formFields];
        expect(fields.map((f) => f.id).toSet().length, fields.length);
        expect(draft.query, isNotEmpty); // Blank rows belong to the editor, not Python.
      }
    });
  }

  for (final reply in ['<html>unavailable</html>', 'null', '[]', '{}',
    '{"schema":"wrong","result":{}}',
    '{"schema":"curl-runtime/1","result":{"ok":"true"}}',
    '{"schema":"curl-runtime/1","result":{"ok":false,"draft":null,"errors":[],"warnings":[]}}',
    '{"schema":"curl-runtime/1","result":{"ok":false,"draft":null,"errors":["raw-secret"],"warnings":[]}}']) {
    test('malformed runtime response is not a legacy-parser success: $reply', () async {
      final result = await importPythonCurl('curl https://example.com/', newId: newId,
          transport: (_) async => reply);
      expect(result.draft, isNull);
      expect(result.errors.single.code, 'httpDraft.curl.error.runtimeResponse');
    });
  }

  test('unavailable runtime does not fall back on syntactically valid curl', () async {
    final result = await importPythonCurl('curl https://example.com/', newId: newId,
        transport: (_) => Future.error(StateError('private diagnostic')));
    expect(result.isOk, isFalse);
    expect(result.errors.single.code, 'httpDraft.curl.error.runtimeUnavailable');
  });

  test('a hanging runtime is bounded and is not success', () async {
    final result = await importPythonCurl('curl https://example.com/', newId: newId,
        timeout: const Duration(milliseconds: 5), transport: (_) => Completer<String>().future);
    expect(result.draft, isNull);
    expect(result.errors.single.code, 'httpDraft.curl.error.runtimeTimeout');
  });

  test('oversized input is rejected before any transport call', () async {
    var called = false;
    final result = await importPythonCurl('a' * 65537, newId: newId,
        transport: (_) async { called = true; return '{}'; });
    expect(called, isFalse);
    expect(result.errors.single.code, 'httpDraft.curl.error.inputTooLarge');
  });
}
