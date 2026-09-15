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
}
