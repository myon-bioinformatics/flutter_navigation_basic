import 'dart:convert';

import 'package:flutter_application_1/shared/http/curl_import.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contract of the editor's entry point, importCurlText, in both builds.
///
/// importPythonCurl itself is covered by curl_python_runtime_test.dart; this
/// file only checks which path the compile-time flag selects. CI runs it twice:
/// as-is (compatibility build) and with --dart-define=CURL_PYTHON_RUNTIME=true.
void main() {
  var sequence = 0;
  String newId() => 'entry-${sequence++}';
  const raw = 'curl https://example.com/';
  // A different URL than [raw] proves the editor got Python's reply, not a
  // local parse of the same text.
  final pythonReply = jsonEncode({
    'schema': 'curl-runtime/1',
    'result': {
      'ok': true, 'errors': [], 'warnings': [],
      'draft': {'method': 'GET', 'url': 'https://python.example/',
        'bodyMode': 'none', 'rawBody': '', 'query': [], 'headers': [],
        'formFields': []},
    },
  });

  // Guards the CI step: a mistyped define would otherwise silently re-run the
  // compatibility tests below.
  const expected = String.fromEnvironment('CURL_RUNTIME_EXPECTED');
  test('compiled runtime mode matches what the runner asked for', () {
    if (expected.isEmpty) return;
    expect(usePythonCurlRuntime, expected == 'true');
  });

  if (usePythonCurlRuntime) {
    test('runtime build sends the text to Python and applies its reply', () async {
      final sent = <String>[];
      final result = await importCurlText(raw, newId: newId,
          transport: (text) async {
            sent.add(text);
            return pythonReply;
          });
      expect(sent, [raw]);
      expect(result.draft?.url, 'https://python.example/');
    });

    test('runtime build stays failed when Python is unreachable', () async {
      // No injected transport: the production default for this platform.
      final result = await importCurlText(raw, newId: newId);
      expect(result.draft, isNull);
      expect(result.errors.single.code, 'httpDraft.curl.error.runtimeUnavailable');
    });
  } else {
    test('compatibility build parses locally and never calls Python', () async {
      var calls = 0;
      final result = await importCurlText(raw, newId: newId,
          transport: (_) async {
            calls++;
            return pythonReply;
          });
      expect(calls, 0);
      expect(result.draft?.url, 'https://example.com/');
    });
  }
}
