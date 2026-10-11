import 'dart:async';

import 'package:flutter_application_1/shared/http/curl_import.dart';
import 'package:flutter_test/flutter_test.dart';

/// Python-enabled import must fail closed; never retry via the legacy Dart
/// curl parser after a transport or protocol failure.
void main() {
  var sequence = 0;
  String newId() => 'boundary-${sequence++}';

  setUp(() => sequence = 0);

  const raw = 'curl https://example.com/path';

  test('unavailable Python transport does not fall back to Dart', () async {
    var calls = 0;
    final result = await importPythonCurl(
      raw,
      newId: newId,
      transport: (_) {
        calls++;
        return Future<String>.error(StateError('offline'));
      },
    );
    expect(calls, 1);
    expect(result.draft, isNull);
    expect(result.errors.map((e) => e.code),
        contains('httpDraft.curl.error.runtimeUnavailable'));
  });

  test('timeout does not fall back to Dart', () async {
    final never = Completer<String>();
    final result = await importPythonCurl(
      raw,
      newId: newId,
      transport: (_) => never.future,
      timeout: const Duration(milliseconds: 1),
    );
    expect(result.draft, isNull);
    expect(result.errors.map((e) => e.code),
        contains('httpDraft.curl.error.runtimeTimeout'));
  });

  test('malformed Python envelope does not fall back to Dart', () async {
    for (final response in <String>[
      'not-json',
      '{}',
      '{"schema":"curl-runtime/1","result":{"ok":true}}',
      '{"schema":"curl-runtime/1","result":{"ok":false,"errors":[],"warnings":[],"draft":null}}',
    ]) {
      final result = await importPythonCurl(
        raw,
        newId: newId,
        transport: (_) async => response,
      );
      expect(result.draft, isNull, reason: response);
      expect(result.errors.map((e) => e.code),
          contains('httpDraft.curl.error.runtimeResponse'),
          reason: response);
    }
  });

  test('Python parser rejection remains rejection without fallback', () async {
    const response =
        '{"schema":"curl-runtime/1","result":{"ok":false,'
        '"errors":["httpDraft.curl.error.unsupportedFlag"],'
        '"warnings":[],"draft":null}}';
    final result = await importPythonCurl(
      raw,
      newId: newId,
      transport: (_) async => response,
    );
    expect(result.draft, isNull);
    expect(result.errors.map((e) => e.code),
        contains('httpDraft.curl.error.unsupportedFlag'));
    expect(result.errors.map((e) => e.code),
        isNot(contains('httpDraft.curl.error.runtimeUnavailable')));
  });
}
