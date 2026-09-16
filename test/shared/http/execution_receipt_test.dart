import 'dart:math';

import 'package:flutter_application_1/shared/http/auth_matrix.dart';
import 'package:flutter_application_1/shared/http/mock_auth.dart';
import 'package:flutter_application_1/shared/http/request_draft.dart';
import 'package:flutter_application_1/shared/http/request_draft_codec.dart';
import 'package:flutter_application_1/shared/http/request_executor.dart';
import 'package:flutter_application_1/shared/http/request_field.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatExecutionReceipt secret safety', () {
    late MockAuthRequestExecutor executor;

    setUp(() {
      final auth = MockAuthHandler();
      executor = MockAuthRequestExecutor(
        handler: ({
          required method,
          required path,
          required headers,
          required query,
          required queryPairs,
          requestTarget,
          body,
        }) {
          final result = auth.handle(
            method: method,
            path: path,
            headers: headers,
            query: query,
            requestTarget: requestTarget,
            body: body,
            queryPairs: queryPairs,
          );
          if (result == null) return null;
          return (
            statusCode: result.statusCode,
            body: result.body,
            headers: result.headers,
          );
        },
      );
    });

    test('receipt omits api_key query secret from entire string', () {
      final draft = AuthMatrixScenario.apiKeyQuery.applyTo(
        const RequestDraft(),
        baseUrl: 'http://127.0.0.1:8787',
      );
      final result = executor.execute(
        draft,
        scenario: AuthMatrixScenario.apiKeyQuery,
      );
      final wire = result.wireDraft ?? draft;
      final curl = RequestDraftCodec.toCurl(wire, redactSecrets: true);
      final receipt = formatExecutionReceipt(
        draft: wire,
        result: result,
        redactedCurl: curl,
      );

      expect(receipt, isNot(contains('demo-api-key')));
      expect(
        receipt.contains('***') || receipt.contains('%2A%2A%2A'),
        isTrue,
      );
      expect(receipt, contains('execution-path:'));
    });

    test('redacted curl omits typed JSON password and opaque raw bodies', () {
      final jsonDraft = RequestDraft(
        method: HttpMethod.post,
        url: 'http://127.0.0.1:8787/echo',
        bodyMode: RequestBodyMode.json,
        jsonFields: const [
          JsonBodyField(
            id: '1',
            name: 'password',
            value: 'super-secret',
            sensitive: true,
          ),
          JsonBodyField(id: '2', name: 'user', value: 'demo'),
        ],
      );
      final jsonCurl =
          RequestDraftCodec.toCurl(jsonDraft, redactSecrets: true);
      expect(jsonCurl, isNot(contains('super-secret')));
      expect(jsonCurl, contains('***'));

      final rawDraft = RequestDraft(
        method: HttpMethod.post,
        url: 'http://127.0.0.1:8787/echo',
        bodyMode: RequestBodyMode.raw,
        rawBody: 'not-json token=abc',
      );
      final rawCurl =
          RequestDraftCodec.toCurl(rawDraft, redactSecrets: true);
      expect(rawCurl, contains('[omitted: opaque raw body]'));
      expect(rawCurl, isNot(contains('token=abc')));
    });

    test('HMAC prepareWireDraft signs before curl export', () {
      final draft = AuthMatrixScenario.hmac.applyTo(
        const RequestDraft(),
        baseUrl: 'http://127.0.0.1:8787',
      );
      final wire = executor.prepareWireDraft(
        draft,
        scenario: AuthMatrixScenario.hmac,
      );
      expect(wire.path, 'hmac');
      final sig = wire.draft.enabledHeaders
          .firstWhere((h) => h.normalizedName == 'x-signature')
          .normalizedValue;
      expect(sig, isNot('pending'));
      final curl =
          RequestDraftCodec.toCurl(wire.draft, redactSecrets: true);
      expect(curl, isNot(contains(sig)));
      expect(curl.toLowerCase(), contains('x-signature'));
    });
  });

  group('mock/live wire parity via shared orchestrator', () {
    late MockAuthRequestExecutor executor;

    MockAuthRouteHandler _handler() {
      final auth = MockAuthHandler();
      return ({
        required method,
        required path,
        required headers,
        required query,
        required queryPairs,
        requestTarget,
        body,
      }) {
        final result = auth.handle(
          method: method,
          path: path,
          headers: headers,
          query: query,
          requestTarget: requestTarget,
          body: body,
          queryPairs: queryPairs,
        );
        if (result == null) return null;
        return (
          statusCode: result.statusCode,
          body: result.body,
          headers: result.headers,
        );
      };
    }

    setUp(() {
      executor = MockAuthRequestExecutor(
        handler: _handler(),
        digestRandom: Random(42),
      );
    });

    String? _header(RequestDraft draft, String name) {
      final wanted = name.toLowerCase();
      for (final field in draft.enabledHeaders) {
        if (field.normalizedName == wanted) return field.normalizedValue;
      }
      return null;
    }

    test('HMAC mock execute and prepareWireDraft share signed wire', () {
      final draft = AuthMatrixScenario.hmac.applyTo(
        const RequestDraft(),
        baseUrl: 'http://127.0.0.1:8787',
      );
      final mock = executor.execute(draft, scenario: AuthMatrixScenario.hmac);
      final prepared = executor.prepareWireDraft(
        draft,
        scenario: AuthMatrixScenario.hmac,
      );
      expect(mock.executionPath, 'hmac');
      expect(prepared.path, 'hmac');
      // execute re-signs (fresh timestamp); path + header names must match.
      expect(_header(mock.wireDraft!, 'x-signature'), isNotNull);
      expect(_header(prepared.draft, 'x-signature'), isNotNull);
      expect(
        RequestDraftCodec.toCurl(mock.wireDraft!, redactSecrets: true)
            .toLowerCase(),
        contains('x-signature'),
      );
    });

    test('Digest mock and prepared retry share Authorization wire', () async {
      final digestExecutor = MockAuthRequestExecutor(
        handler: _handler(),
        digestRandom: Random(7),
      );
      final draft = AuthMatrixScenario.digest.applyTo(
        const RequestDraft(),
        baseUrl: 'http://127.0.0.1:8787',
      );

      final mock = digestExecutor.execute(
        draft,
        scenario: AuthMatrixScenario.digest,
      );
      expect(mock.executionPath, 'digest-retry');
      expect(mock.statusCode, 200);

      final liveStyle = MockAuthRequestExecutor(
        handler: _handler(),
        digestRandom: Random(7),
      );
      final prepared = await liveStyle.executePrepared(
        draft,
        scenario: AuthMatrixScenario.digest,
        dispatch: (d) async {
          final pairs = MockAuthRequestExecutor.orderedQueryPairs(d);
          final path = Uri.parse(d.normalizedUrl).path;
          final queryString =
              MockAuthRequestExecutor.encodeQueryPairs(pairs);
          final target =
              queryString.isEmpty ? path : '$path?$queryString';
          final body =
              RequestDraftCodec.buildBody(d, redactSecrets: false);
          final headers = <String, String>{
            for (final field in d.enabledHeaders)
              field.name.trim(): field.normalizedValue,
          };
          final query = <String, String>{
            for (final pair in pairs) pair.name: pair.value,
          };
          final auth = liveStyle.handler(
            method: d.method.label,
            path: path,
            headers: headers,
            query: query,
            queryPairs: pairs,
            requestTarget: target,
            body: body,
          )!;
          return RequestExecutionResult(
            statusCode: auth.statusCode,
            body: auth.body,
            headers: auth.headers,
            requestTarget: target,
            wireDraft: d,
          );
        },
        basePath: 'live',
      );

      expect(prepared.executionPath, 'live-digest-retry');
      expect(prepared.statusCode, 200);
      expect(
        _header(mock.wireDraft!, 'authorization'),
        _header(prepared.wireDraft!, 'authorization'),
      );
      expect(
        RequestDraftCodec.toCurl(mock.wireDraft!, redactSecrets: true),
        RequestDraftCodec.toCurl(prepared.wireDraft!, redactSecrets: true),
      );
      expect(
        RequestDraftCodec.toCurl(mock.wireDraft!, redactSecrets: true),
        isNot(contains('s3cret')),
      );
    });

    test('orderedWireQueryPairs matches codec and executor', () {
      const draft = RequestDraft(
        url: 'http://127.0.0.1:8787/echo?b=1&a=2&b=3',
        query: [
          RequestField(id: 'q1', name: 'z', value: '9'),
        ],
      );
      final fromCodec = RequestDraftCodec.orderedWireQueryPairs(draft);
      final fromExecutor = MockAuthRequestExecutor.orderedQueryPairs(draft);
      expect(fromExecutor.map((p) => '${p.name}=${p.value}').toList(), [
        'b=1',
        'a=2',
        'b=3',
        'z=9',
      ]);
      expect(
        fromCodec.map((p) => '${p.name}=${p.value}').toList(),
        fromExecutor.map((p) => '${p.name}=${p.value}').toList(),
      );
    });
  });
}
