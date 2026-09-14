import 'dart:convert';

import 'package:flutter_application_1/shared/http/curl_safe_subset.dart';
import 'package:flutter_application_1/shared/http/request_draft.dart';
import 'package:flutter_application_1/shared/http/request_field.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var seq = 0;
  String newId() => 't${seq++}';

  setUp(() => seq = 0);

  group('CurlSafeSubset.tryParse', () {
    test('imports method, url, headers, and json body', () {
      const curl = r'''
curl -X POST 'https://example.com/api' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer secret-token' \
  --data-raw '{"ok":true}'
''';
      final result = CurlSafeSubset.tryParse(curl, newId: newId);
      expect(result.isOk, isTrue);
      final draft = result.draft!;
      expect(draft.method, HttpMethod.post);
      expect(draft.url, 'https://example.com/api');
      expect(draft.bodyMode, RequestBodyMode.json);
      expect(draft.rawBody, '{"ok":true}');
      final auth = draft.headers.firstWhere(
        (h) => h.normalizedName == 'authorization',
      );
      expect(auth.sensitive, isTrue);
      expect(auth.value, 'Bearer secret-token');
    });

    test('normalizes fullwidth curl before parse', () {
      const curl = 'ｃｕｒｌ －Ｘ ＧＥＴ ｈｔｔｐｓ：／／ｅｘａｍｐｌｅ．ｃｏｍ／';
      final result = CurlSafeSubset.tryParse(curl, newId: newId);
      expect(result.isOk, isTrue);
      expect(result.draft!.method, HttpMethod.get);
      expect(result.draft!.url, 'https://example.com/');
    });

    test('maps -u to sensitive Basic Authorization', () {
      final result = CurlSafeSubset.tryParse(
        "curl -u 'alice:s3cret' https://example.com/x",
        newId: newId,
      );
      expect(result.isOk, isTrue);
      final auth = result.draft!.headers.firstWhere(
        (h) => h.normalizedName == 'authorization',
      );
      expect(auth.sensitive, isTrue);
      expect(auth.value, 'Basic ${base64Encode(utf8.encode('alice:s3cret'))}');
      expect(
        result.warnings.map((w) => w.code),
        contains('httpDraft.curl.warn.basicAuthMapped'),
      );
    });

    test('empty quoted args are kept so flags do not steal the next token', () {
      final result = CurlSafeSubset.tryParse(
        "curl https://example.com/ -H '' 'Y: 1'",
        newId: newId,
      );
      // Empty -H value must not become header "Y: 1".
      expect(result.isOk, isFalse);
      expect(
        result.errors.map((e) => e.code),
        contains('httpDraft.curl.error.badHeader'),
      );
      expect(result.draft, isNull);

      final data = CurlSafeSubset.tryParse(
        "curl https://example.com/ -d '' 'not-body'",
        newId: newId,
      );
      // Empty -d consumes ''; leftover positional must not silently become URL.
      expect(data.isOk, isFalse);
      expect(data.draft, isNull);
    });

    test('rejects shell metacharacters outside quotes', () {
      final result = CurlSafeSubset.tryParse(
        'curl https://example.com/ | tee out',
        newId: newId,
      );
      expect(result.isOk, isFalse);
      expect(
        result.errors.map((e) => e.code),
        contains('httpDraft.curl.error.shellMeta'),
      );
    });

    test('rejects @file bodies', () {
      final result = CurlSafeSubset.tryParse(
        "curl -d @secret.json https://example.com/",
        newId: newId,
      );
      expect(result.isOk, isFalse);
      expect(
        result.errors.map((e) => e.code),
        contains('httpDraft.curl.error.fileBody'),
      );
    });

    test('rejects --proxy and unknown long options fail-closed', () {
      for (final flag in [
        '--proxy http://p',
        '--proxy=http://p',
        '--config ./curlrc',
        '--compressed',
        '--max-time 5',
      ]) {
        final result = CurlSafeSubset.tryParse(
          'curl $flag https://example.com/',
          newId: newId,
        );
        expect(result.isOk, isFalse, reason: flag);
        expect(
          result.errors.map((e) => e.code),
          contains('httpDraft.curl.error.unsupportedFlag'),
        );
        // Must not silently succeed with a shifted URL/body.
        expect(result.draft, isNull);
      }
    });

    test('accepts --flag=value for supported long options', () {
      final result = CurlSafeSubset.tryParse(
        r'''curl --request=POST --url=https://example.com/api '''
        r'''--header=Content-Type:application/json '''
        r"""--data-raw='{"ok":true}'""",
        newId: newId,
      );
      expect(result.isOk, isTrue);
      final draft = result.draft!;
      expect(draft.method, HttpMethod.post);
      expect(draft.url, 'https://example.com/api');
      expect(draft.bodyMode, RequestBodyMode.json);
      expect(draft.rawBody, '{"ok":true}');
      expect(
        draft.headers.any((h) => h.normalizedName == 'content-type'),
        isTrue,
      );
    });

    test('rejects @file and name@file data-urlencode forms', () {
      for (final body in ['@secret.json', 'payload@secret.json']) {
        final result = CurlSafeSubset.tryParse(
          "curl --data-urlencode '$body' https://example.com/",
          newId: newId,
        );
        expect(result.isOk, isFalse, reason: body);
        expect(
          result.errors.map((e) => e.code),
          contains('httpDraft.curl.error.fileBody'),
        );
      }

      final safe = CurlSafeSubset.tryParse(
        "curl --data-urlencode 'a=b' --data-urlencode '=c' --data-urlencode 'plain' https://example.com/",
        newId: newId,
      );
      expect(safe.isOk, isTrue);
      expect(
        safe.draft!.formFields.map((f) => '${f.name}=${f.value}'),
        containsAll(['a=b', '=c', 'plain=']),
      );
    });

    test('imports form urlencode fields', () {
      final result = CurlSafeSubset.tryParse(
        "curl --data-urlencode 'a=b c' --data-urlencode 'd=e' https://example.com/",
        newId: newId,
      );
      expect(result.isOk, isTrue);
      expect(result.draft!.bodyMode, RequestBodyMode.formUrlEncoded);
      expect(result.draft!.method, HttpMethod.post);
      expect(
        result.draft!.formFields.map((f) => '${f.name}=${f.value}'),
        containsAll(['a=b c', 'd=e']),
      );
    });

    test('redacted export never leaks bearer token', () {
      final draft = RequestDraft(
        url: 'https://example.com',
        headers: const [
          RequestField(
            id: '1',
            name: 'Authorization',
            value: 'Bearer leak-me',
            sensitive: true,
          ),
        ],
      );
      final exported = CurlSafeSubset.export(draft);
      expect(exported, contains('***'));
      expect(exported, isNot(contains('leak-me')));
    });

    test('round-trip preserves method and url through export/import', () {
      final original = RequestDraft(
        method: HttpMethod.put,
        url: 'https://example.com/items/1',
        headers: const [
          RequestField(id: '1', name: 'Accept', value: 'application/json'),
        ],
        bodyMode: RequestBodyMode.raw,
        rawBody: 'payload',
      );
      final curl = CurlSafeSubset.export(original, redactSecrets: false);
      final parsed = CurlSafeSubset.tryParse(curl, newId: newId);
      expect(parsed.isOk, isTrue);
      expect(parsed.draft!.method, HttpMethod.put);
      expect(parsed.draft!.url, 'https://example.com/items/1');
      expect(parsed.draft!.rawBody, 'payload');
    });
  });
}
