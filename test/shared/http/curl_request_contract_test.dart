import 'dart:convert';
import 'dart:io';

import 'package:flutter_application_1/shared/http/curl_import_legacy.dart';
import 'package:flutter_application_1/shared/http/curl_import_result.dart';
import 'package:flutter_application_1/shared/http/request_field.dart';
import 'package:flutter_test/flutter_test.dart';

// The same explicit cases run through Python in test_curl_request.py.
// Compare import-stage data only, without editor IDs/blank rows or the later
// RequestDraftValidator warnings. This is not a runtime Python bridge.
List<Map<String, Object?>> _rows(List<RequestField> fields) => [
      for (final field in fields)
        if (field.name.isNotEmpty || field.value.isNotEmpty)
          {
            'name': field.name,
            'value': field.value,
            'sensitive': field.sensitive,
          },
    ];

Map<String, Object?> _snapshot(CurlImportResult result) {
  final draft = result.draft;
  return {
    'ok': result.isOk,
    'draft': draft == null
        ? null
        : {
            'method': draft.method.name.toUpperCase(),
            'url': draft.url,
            'headers': _rows(draft.headers),
            'query': _rows(draft.query),
            'bodyMode': draft.bodyMode.name,
            'rawBody': draft.rawBody,
            'formFields': _rows(draft.formFields),
          },
    'errors': [for (final issue in result.errors) issue.code],
    'warnings': [
      for (final issue in result.warnings)
        if (issue.code.startsWith('httpDraft.curl.')) issue.code,
    ],
  };
}

void main() {
  final fixture = jsonDecode(
    File('tool/python/fixtures/curl_request_cases.json')
        .readAsStringSync(encoding: utf8),
  ) as Map<String, dynamic>;
  final cases = fixture['cases'] as List<dynamic>;

  group('shared Python/Dart curl import contract', () {
    test('fixture schema and unique case IDs', () {
      expect(fixture['schema'], 'curl-import-cases/1');
      expect(cases, isNotEmpty);
      expect(cases.map((item) => item['id']).toSet().length, cases.length);
    });
    for (final item in cases) {
      final data = item as Map<String, dynamic>;
      test(data['id'] as String, () {
        var seq = 0;
        final result = importLegacyCurl(
          data['input'] as String,
          newId: () => 'contract-${seq++}',
        );
        expect(_snapshot(result), equals(data['expected']));
      });
    }
  });
}
