import 'package:flutter_application_1/shared/http/request_draft.dart';
import 'package:flutter_application_1/shared/http/request_draft_codec.dart';
import 'package:flutter_application_1/shared/http/request_field.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RequestDraftValidator', () {
    test('flags duplicate headers case-insensitively after fullwidth normalize',
        () {
      final draft = RequestDraft(
        url: 'https://example.com',
        headers: [
          const RequestField(id: '1', name: 'Authorization', value: 'a'),
          const RequestField(id: '2', name: 'ａｕｔｈｏｒｉｚａｔｉｏｎ', value: 'b'),
        ],
      );
      final issues = RequestDraftValidator.validate(draft);
      expect(
        issues.map((i) => i.code),
        contains('httpDraft.error.duplicateHeader'),
      );
      expect(draft.duplicateHeaderNames, contains('authorization'));
    });

    test('flags CR/LF in header name or value', () {
      final draft = RequestDraft(
        url: 'https://example.com',
        headers: const [
          RequestField(id: '1', name: 'X-Foo\nBar', value: '1'),
        ],
      );
      expect(
        RequestDraftValidator.validate(draft).map((i) => i.code),
        contains('httpDraft.error.headerCrLf'),
      );
    });

    test('flags invalid JSON body', () {
      final draft = RequestDraft(
        url: 'https://example.com',
        bodyMode: RequestBodyMode.json,
        rawBody: '{not-json',
      );
      expect(
        RequestDraftValidator.validate(draft).map((i) => i.code),
        contains('httpDraft.error.jsonInvalid'),
      );
    });
  });

  group('RequestDraftCodec', () {
    test('merges fullwidth query and builds ASCII URI', () {
      final draft = RequestDraft(
        url: 'ｈｔｔｐｓ：／／ｅｘａｍｐｌｅ．ｃｏｍ／ｐａｔｈ',
        query: const [
          RequestField(id: '1', name: 'ｑ', value: '３５'),
        ],
      );
      final uri = RequestDraftCodec.buildUri(draft)!;
      expect(uri.scheme, 'https');
      expect(uri.host, 'example.com');
      expect(uri.queryParameters['q'], '35');
    });

    test('preserves duplicate query keys and order', () {
      final draft = RequestDraft(
        url: 'https://example.com/path?tag=a&keep=1',
        query: const [
          RequestField(id: '1', name: 'tag', value: 'b'),
          RequestField(id: '2', name: 'empty', value: ''),
        ],
      );
      final uri = RequestDraftCodec.buildUri(draft)!;
      expect(uri.query, 'tag=a&keep=1&tag=b&empty=');
      expect(uri.queryParametersAll['tag'], ['a', 'b']);
    });

    test('redacts sensitive query names and URL userInfo in curl', () {
      final draft = RequestDraft(
        url: 'https://user:pass@example.com/api?api_key=from-url&ok=1',
        query: const [
          RequestField(id: '1', name: 'token', value: 'query-secret'),
          RequestField(
            id: '2',
            name: 'note',
            value: 'visible',
            sensitive: true,
          ),
        ],
      );
      final uri = RequestDraftCodec.buildUri(draft, redactSecrets: true)!;
      expect(uri.userInfo, '***');
      expect(uri.query, contains('api_key=%2A%2A%2A'));
      expect(uri.query, contains('token=%2A%2A%2A'));
      expect(uri.query, contains('note=%2A%2A%2A'));
      expect(uri.query, contains('ok=1'));
      expect(uri.query, isNot(contains('from-url')));
      expect(uri.query, isNot(contains('query-secret')));

      final curl = RequestDraftCodec.toCurl(draft);
      expect(curl, contains('***'));
      expect(curl, isNot(contains('from-url')));
      expect(curl, isNot(contains('query-secret')));
      expect(curl, isNot(contains('user:pass')));
    });

    test('form-urlencoded encodes fields', () {
      final draft = RequestDraft(
        url: 'https://example.com',
        bodyMode: RequestBodyMode.formUrlEncoded,
        formFields: const [
          RequestField(id: '1', name: 'a b', value: 'c&d'),
        ],
      );
      expect(
        RequestDraftCodec.buildBody(draft, redactSecrets: true),
        'a+b=c%26d',
      );
    });

    test('redacts sensitive headers in preview and curl', () {
      final draft = RequestDraft(
        method: HttpMethod.post,
        url: 'https://example.com/api',
        headers: const [
          RequestField(
            id: '1',
            name: 'Authorization',
            value: 'Bearer super-secret-token',
          ),
          RequestField(
            id: '2',
            name: 'X-Custom',
            value: 'visible',
            sensitive: true,
          ),
        ],
        bodyMode: RequestBodyMode.raw,
        rawBody: 'hello',
      );

      final headers =
          RequestDraftCodec.buildHeaders(draft, redactSecrets: true);
      expect(headers['Authorization'], '***');
      expect(headers['X-Custom'], '***');

      final curl = RequestDraftCodec.toCurl(draft);
      expect(curl, contains('***'));
      expect(curl, isNot(contains('super-secret-token')));
      expect(curl, isNot(contains('Bearer super-secret')));
    });

    test('add/edit/delete field list stays immutable via copyWith', () {
      var draft = RequestDraft.empty();
      draft = draft.copyWith(
        headers: [
          const RequestField(id: '1', name: 'Accept', value: 'json'),
        ],
      );
      expect(draft.headers, hasLength(1));
      draft = draft.copyWith(
        headers: [
          ...draft.headers,
          const RequestField(id: '2', name: 'X-Trace', value: '1'),
        ],
      );
      expect(draft.headers, hasLength(2));
      draft = draft.copyWith(
        headers: draft.headers
            .map(
              (f) => f.id == '1' ? f.copyWith(value: 'application/json') : f,
            )
            .toList(),
      );
      expect(draft.headers.first.value, 'application/json');
      draft = draft.copyWith(
        headers: draft.headers.where((f) => f.id != '2').toList(),
      );
      expect(draft.headers, hasLength(1));
    });
  });
}
