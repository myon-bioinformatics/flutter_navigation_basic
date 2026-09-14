import 'request_draft.dart';
import 'request_field.dart';

/// Demo auth presets for the local mock `/auth/*` matrix (fixture credentials).
///
/// These are intentionally public demo values — never production secrets.
/// Live JWT verification must **not** use the unsigned foundation inspector.
enum AuthMatrixScenario {
  none,
  bearer,
  bearerExpired,
  bearerWrongAudience,
  apiKeyHeader,
  apiKeyQuery,
  basic,
  digestChallengeOnly,
  hmac,
  rateLimited,
}

extension AuthMatrixScenarioX on AuthMatrixScenario {
  String get id => name;

  String get label => switch (this) {
        AuthMatrixScenario.none => 'No auth',
        AuthMatrixScenario.bearer => 'Bearer (valid demo)',
        AuthMatrixScenario.bearerExpired => 'Bearer (expired)',
        AuthMatrixScenario.bearerWrongAudience => 'Bearer (wrong audience)',
        AuthMatrixScenario.apiKeyHeader => 'API key (header)',
        AuthMatrixScenario.apiKeyQuery => 'API key (query)',
        AuthMatrixScenario.basic => 'HTTP Basic',
        AuthMatrixScenario.digestChallengeOnly => 'Digest (challenge path)',
        AuthMatrixScenario.hmac => 'HMAC-SHA256',
        AuthMatrixScenario.rateLimited => 'Rate limited (429)',
      };

  /// Relative mock path for this scenario.
  String get mockPath => switch (this) {
        AuthMatrixScenario.none => '/health',
        AuthMatrixScenario.bearer ||
        AuthMatrixScenario.bearerExpired ||
        AuthMatrixScenario.bearerWrongAudience =>
          '/auth/bearer',
        AuthMatrixScenario.apiKeyHeader ||
        AuthMatrixScenario.apiKeyQuery =>
          '/auth/api-key',
        AuthMatrixScenario.basic => '/auth/basic',
        AuthMatrixScenario.digestChallengeOnly => '/auth/digest',
        AuthMatrixScenario.hmac => '/auth/hmac',
        AuthMatrixScenario.rateLimited => '/auth/rate-limited',
      };

  /// Applies fixture credentials onto a draft aimed at [baseUrl].
  RequestDraft applyTo(
    RequestDraft draft, {
    required String baseUrl,
  }) {
    final root = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = '$root$mockPath';
    final next = draft.copyWith(
      method: HttpMethod.get,
      url: url,
      query: const [],
      headers: const [],
      bodyMode: RequestBodyMode.none,
      rawBody: '',
      formFields: const [],
      jsonFields: const [],
    );

    RequestField h(String name, String value, {bool sensitive = false}) =>
        RequestField(
          id: 'auth-$name',
          name: name,
          value: value,
          sensitive: sensitive,
        );

    switch (this) {
      case AuthMatrixScenario.none:
        return next;
      case AuthMatrixScenario.bearer:
        return next.copyWith(
          headers: [
            h('Authorization', 'Bearer demo-bearer-token', sensitive: true),
          ],
        );
      case AuthMatrixScenario.bearerExpired:
        return next.copyWith(
          headers: [
            h('Authorization', 'Bearer demo-expired-token', sensitive: true),
          ],
        );
      case AuthMatrixScenario.bearerWrongAudience:
        return next.copyWith(
          headers: [
            h(
              'Authorization',
              'Bearer demo-wrong-aud-token',
              sensitive: true,
            ),
          ],
        );
      case AuthMatrixScenario.apiKeyHeader:
        return next.copyWith(
          headers: [h('X-Api-Key', 'demo-api-key', sensitive: true)],
        );
      case AuthMatrixScenario.apiKeyQuery:
        return next.copyWith(
          query: [
            const RequestField(
              id: 'auth-q',
              name: 'api_key',
              value: 'demo-api-key',
              sensitive: true,
            ),
          ],
        );
      case AuthMatrixScenario.basic:
        // demo:s3cret → ZGVtbzpzM2NyZXQ=
        return next.copyWith(
          headers: [
            h('Authorization', 'Basic ZGVtbzpzM2NyZXQ=', sensitive: true),
          ],
        );
      case AuthMatrixScenario.digestChallengeOnly:
        return next;
      case AuthMatrixScenario.hmac:
        return next.copyWith(
          headers: [
            h('X-Key-Id', 'demo-key'),
            h('X-Timestamp', '0'),
            h('X-Nonce', 'pending'),
            h('X-Signature', 'pending', sensitive: true),
          ],
        );
      case AuthMatrixScenario.rateLimited:
        return next;
    }
  }
}
