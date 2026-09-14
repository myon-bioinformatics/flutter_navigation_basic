import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/mock_auth.dart';

void main() {
  group('MockAuthHandler bearer', () {
    late MockAuthHandler auth;

    setUp(() => auth = MockAuthHandler());

    test('missing authorization → 401', () {
      final result = auth.handle(
        method: 'GET',
        path: '/auth/bearer',
        headers: const {},
        query: const {},
      )!;
      expect(result.statusCode, 401);
      expect(result.body['reason'], 'missing_authorization');
      expect(result.headers['www-authenticate'], contains('Bearer'));
    });

    test('malformed authorization → 401', () {
      final result = auth.handle(
        method: 'GET',
        path: '/auth/bearer',
        headers: const {'authorization': 'Token nope'},
        query: const {},
      )!;
      expect(result.statusCode, 401);
      expect(result.body['reason'], 'malformed_authorization');
    });

    test('expired / wrong audience / valid tokens', () {
      final expired = auth.handle(
        method: 'GET',
        path: '/auth/bearer',
        headers: {
          'authorization': 'Bearer ${MockAuthDemo.bearerExpiredToken}',
        },
        query: const {},
      )!;
      expect(expired.statusCode, 401);
      expect(expired.body['reason'], 'expired');

      final wrongAud = auth.handle(
        method: 'GET',
        path: '/auth/bearer',
        headers: {
          'authorization': 'Bearer ${MockAuthDemo.bearerWrongAudienceToken}',
        },
        query: const {},
      )!;
      expect(wrongAud.statusCode, 403);
      expect(wrongAud.body['reason'], 'wrong_audience');

      final ok = auth.handle(
        method: 'GET',
        path: '/auth/bearer',
        headers: {
          'authorization': 'Bearer ${MockAuthDemo.bearerToken}',
        },
        query: const {},
      )!;
      expect(ok.statusCode, 200);
      expect(ok.body['ok'], isTrue);
    });
  });

  group('MockAuthHandler api-key', () {
    late MockAuthHandler auth;
    setUp(() => auth = MockAuthHandler());

    test('missing / wrong / header / query', () {
      expect(
        auth
            .handle(
              method: 'GET',
              path: '/auth/api-key',
              headers: const {},
              query: const {},
            )!
            .statusCode,
        401,
      );
      expect(
        auth
            .handle(
              method: 'GET',
              path: '/auth/api-key',
              headers: const {'x-api-key': 'nope'},
              query: const {},
            )!
            .statusCode,
        403,
      );
      expect(
        auth
            .handle(
              method: 'GET',
              path: '/auth/api-key',
              headers: {'x-api-key': MockAuthDemo.apiKey},
              query: const {},
            )!
            .body['via'],
        'header',
      );
      expect(
        auth
            .handle(
              method: 'GET',
              path: '/auth/api-key',
              headers: const {},
              query: {'api_key': MockAuthDemo.apiKey},
            )!
            .body['via'],
        'query',
      );
    });
  });

  group('MockAuthHandler basic', () {
    late MockAuthHandler auth;
    setUp(() => auth = MockAuthHandler());

    test('challenge then accepts demo credentials', () {
      final challenge = auth.handle(
        method: 'GET',
        path: '/auth/basic',
        headers: const {},
        query: const {},
      )!;
      expect(challenge.statusCode, 401);
      expect(challenge.headers['www-authenticate'], startsWith('Basic '));

      final encoded = base64Encode(
        utf8.encode('${MockAuthDemo.basicUser}:${MockAuthDemo.basicPassword}'),
      );
      final ok = auth.handle(
        method: 'GET',
        path: '/auth/basic',
        headers: {'authorization': 'Basic $encoded'},
        query: const {},
      )!;
      expect(ok.statusCode, 200);

      final wrong = auth.handle(
        method: 'GET',
        path: '/auth/basic',
        headers: {
          'authorization':
              'Basic ${base64Encode(utf8.encode('demo:wrong'))}',
        },
        query: const {},
      )!;
      expect(wrong.statusCode, 401);
      expect(wrong.body['reason'], 'invalid_credentials');
    });
  });

  group('MockAuthHandler digest', () {
    late MockAuthHandler auth;
    setUp(() => auth = MockAuthHandler());

    test('challenge then accepts qop=auth response', () {
      final challenge = auth.handle(
        method: 'GET',
        path: '/auth/digest',
        headers: const {},
        query: const {},
      )!;
      expect(challenge.statusCode, 401);
      expect(challenge.headers['www-authenticate'], contains('Digest'));

      const uri = '/auth/digest';
      const nc = '00000001';
      const cnonce = 'demo-cnonce';
      final response = MockAuthHandler.digestResponse(
        method: 'GET',
        uri: uri,
        username: MockAuthDemo.basicUser,
        password: MockAuthDemo.basicPassword,
        realm: MockAuthDemo.digestRealm,
        nonce: MockAuthDemo.digestNonce,
        nc: nc,
        cnonce: cnonce,
      );
      final header = 'Digest username="${MockAuthDemo.basicUser}", '
          'realm="${MockAuthDemo.digestRealm}", '
          'nonce="${MockAuthDemo.digestNonce}", '
          'uri="$uri", '
          'qop=auth, nc=$nc, cnonce="$cnonce", '
          'response="$response", '
          'opaque="${MockAuthDemo.digestOpaque}"';
      final ok = auth.handle(
        method: 'GET',
        path: uri,
        headers: {'authorization': header},
        query: const {},
      )!;
      expect(ok.statusCode, 200);
      expect(ok.body['scheme'], 'digest');
    });

    test('mismatched claimed uri → 401', () {
      const nc = '00000001';
      const cnonce = 'demo-cnonce';
      // Compute a valid digest for '/other/path' but send request to /auth/digest
      final response = MockAuthHandler.digestResponse(
        method: 'GET',
        uri: '/other/path',
        username: MockAuthDemo.basicUser,
        password: MockAuthDemo.basicPassword,
        realm: MockAuthDemo.digestRealm,
        nonce: MockAuthDemo.digestNonce,
        nc: nc,
        cnonce: cnonce,
      );
      final header = 'Digest username="${MockAuthDemo.basicUser}", '
          'realm="${MockAuthDemo.digestRealm}", '
          'nonce="${MockAuthDemo.digestNonce}", '
          'uri="/other/path", '
          'qop=auth, nc=$nc, cnonce="$cnonce", '
          'response="$response", '
          'opaque="${MockAuthDemo.digestOpaque}"';
      final result = auth.handle(
        method: 'GET',
        path: '/auth/digest',
        headers: {'authorization': header},
        query: const {},
      )!;
      expect(result.statusCode, 401);
      expect(result.body['reason'], 'uri_mismatch');
    });

    test('missing qop → 401', () {
      const nc = '00000001';
      const cnonce = 'demo-cnonce';
      final response = MockAuthHandler.digestResponse(
        method: 'GET',
        uri: '/auth/digest',
        username: MockAuthDemo.basicUser,
        password: MockAuthDemo.basicPassword,
        realm: MockAuthDemo.digestRealm,
        nonce: MockAuthDemo.digestNonce,
        nc: nc,
        cnonce: cnonce,
      );
      // Omit qop from the Authorization header
      final header = 'Digest username="${MockAuthDemo.basicUser}", '
          'realm="${MockAuthDemo.digestRealm}", '
          'nonce="${MockAuthDemo.digestNonce}", '
          'uri="/auth/digest", '
          'nc=$nc, cnonce="$cnonce", '
          'response="$response", '
          'opaque="${MockAuthDemo.digestOpaque}"';
      final result = auth.handle(
        method: 'GET',
        path: '/auth/digest',
        headers: {'authorization': header},
        query: const {},
      )!;
      expect(result.statusCode, 401);
      expect(result.body['reason'], 'missing_qop_params');
    });

    test('missing nc → 401', () {
      const cnonce = 'demo-cnonce';
      final response = MockAuthHandler.digestResponse(
        method: 'GET',
        uri: '/auth/digest',
        username: MockAuthDemo.basicUser,
        password: MockAuthDemo.basicPassword,
        realm: MockAuthDemo.digestRealm,
        nonce: MockAuthDemo.digestNonce,
        nc: '00000001',
        cnonce: cnonce,
      );
      // Omit nc
      final header = 'Digest username="${MockAuthDemo.basicUser}", '
          'realm="${MockAuthDemo.digestRealm}", '
          'nonce="${MockAuthDemo.digestNonce}", '
          'uri="/auth/digest", '
          'qop=auth, cnonce="$cnonce", '
          'response="$response", '
          'opaque="${MockAuthDemo.digestOpaque}"';
      final result = auth.handle(
        method: 'GET',
        path: '/auth/digest',
        headers: {'authorization': header},
        query: const {},
      )!;
      expect(result.statusCode, 401);
      expect(result.body['reason'], 'missing_qop_params');
    });

    test('missing cnonce → 401', () {
      const nc = '00000001';
      final response = MockAuthHandler.digestResponse(
        method: 'GET',
        uri: '/auth/digest',
        username: MockAuthDemo.basicUser,
        password: MockAuthDemo.basicPassword,
        realm: MockAuthDemo.digestRealm,
        nonce: MockAuthDemo.digestNonce,
        nc: nc,
        cnonce: 'demo-cnonce',
      );
      // Omit cnonce
      final header = 'Digest username="${MockAuthDemo.basicUser}", '
          'realm="${MockAuthDemo.digestRealm}", '
          'nonce="${MockAuthDemo.digestNonce}", '
          'uri="/auth/digest", '
          'qop=auth, nc=$nc, '
          'response="$response", '
          'opaque="${MockAuthDemo.digestOpaque}"';
      final result = auth.handle(
        method: 'GET',
        path: '/auth/digest',
        headers: {'authorization': header},
        query: const {},
      )!;
      expect(result.statusCode, 401);
      expect(result.body['reason'], 'missing_qop_params');
    });

    test('binds uri to path?query request-target', () {
      const target = '/auth/digest?x=1';
      const nc = '00000001';
      const cnonce = 'demo-cnonce';
      final response = MockAuthHandler.digestResponse(
        method: 'GET',
        uri: target,
        username: MockAuthDemo.basicUser,
        password: MockAuthDemo.basicPassword,
        realm: MockAuthDemo.digestRealm,
        nonce: MockAuthDemo.digestNonce,
        nc: nc,
        cnonce: cnonce,
      );
      final header = 'Digest username="${MockAuthDemo.basicUser}", '
          'realm="${MockAuthDemo.digestRealm}", '
          'nonce="${MockAuthDemo.digestNonce}", '
          'uri="$target", '
          'qop=auth, nc=$nc, cnonce="$cnonce", '
          'response="$response", '
          'opaque="${MockAuthDemo.digestOpaque}"';
      final ok = auth.handle(
        method: 'GET',
        path: '/auth/digest',
        headers: {'authorization': header},
        query: const {'x': '1'},
        requestTarget: target,
      )!;
      expect(ok.statusCode, 200);

      // Same digest claimed against path-only target must fail.
      final mismatch = auth.handle(
        method: 'GET',
        path: '/auth/digest',
        headers: {'authorization': header},
        query: const {'x': '1'},
      )!;
      // Derived target is /auth/digest?x=1, claimed uri matches → still 200
      // when requestTarget omitted. Claim path-only uri instead:
      final pathOnly = MockAuthHandler.digestResponse(
        method: 'GET',
        uri: '/auth/digest',
        username: MockAuthDemo.basicUser,
        password: MockAuthDemo.basicPassword,
        realm: MockAuthDemo.digestRealm,
        nonce: MockAuthDemo.digestNonce,
        nc: nc,
        cnonce: cnonce,
      );
      final pathHeader = 'Digest username="${MockAuthDemo.basicUser}", '
          'realm="${MockAuthDemo.digestRealm}", '
          'nonce="${MockAuthDemo.digestNonce}", '
          'uri="/auth/digest", '
          'qop=auth, nc=$nc, cnonce="$cnonce", '
          'response="$pathOnly", '
          'opaque="${MockAuthDemo.digestOpaque}"';
      final bad = auth.handle(
        method: 'GET',
        path: '/auth/digest',
        headers: {'authorization': pathHeader},
        query: const {'x': '1'},
      )!;
      expect(bad.statusCode, 401);
      expect(bad.body['reason'], 'uri_mismatch');
      expect(mismatch.statusCode, 200);
    });

    test('missing opaque → 401', () {
      const uri = '/auth/digest';
      const nc = '00000001';
      const cnonce = 'demo-cnonce';
      final response = MockAuthHandler.digestResponse(
        method: 'GET',
        uri: uri,
        username: MockAuthDemo.basicUser,
        password: MockAuthDemo.basicPassword,
        realm: MockAuthDemo.digestRealm,
        nonce: MockAuthDemo.digestNonce,
        nc: nc,
        cnonce: cnonce,
      );
      final header = 'Digest username="${MockAuthDemo.basicUser}", '
          'realm="${MockAuthDemo.digestRealm}", '
          'nonce="${MockAuthDemo.digestNonce}", '
          'uri="$uri", '
          'qop=auth, nc=$nc, cnonce="$cnonce", '
          'response="$response"';
      final result = auth.handle(
        method: 'GET',
        path: uri,
        headers: {'authorization': header},
        query: const {},
      )!;
      expect(result.statusCode, 401);
      expect(result.body['reason'], 'invalid_opaque');
    });
  });

  group('MockAuthHandler hmac', () {
    test('missing headers / skew / bad signature / replay', () {
      final fixedNow = DateTime.utc(2026, 9, 14, 12, 0, 0);
      final auth = MockAuthHandler(clock: () => fixedNow);
      final ts = (fixedNow.millisecondsSinceEpoch ~/ 1000).toString();

      expect(
        auth
            .handle(
              method: 'GET',
              path: '/auth/hmac',
              headers: const {},
              query: const {},
            )!
            .body['reason'],
        'missing_hmac_headers',
      );

      final skew = auth.handle(
        method: 'GET',
        path: '/auth/hmac',
        headers: {
          'x-key-id': MockAuthDemo.hmacKeyId,
          'x-timestamp': '1',
          'x-nonce': 'n1',
          'x-signature': 'deadbeef',
        },
        query: const {},
      )!;
      expect(skew.body['reason'], 'timestamp_skew');

      final badSig = auth.handle(
        method: 'GET',
        path: '/auth/hmac',
        headers: {
          'x-key-id': MockAuthDemo.hmacKeyId,
          'x-timestamp': ts,
          'x-nonce': 'n2',
          'x-signature': 'deadbeef',
        },
        query: const {},
      )!;
      expect(badSig.body['reason'], 'invalid_signature');

      final sig = MockAuthHandler.hmacSignature(
        method: 'GET',
        path: '/auth/hmac',
        timestamp: ts,
        nonce: 'n3',
      );
      final ok = auth.handle(
        method: 'GET',
        path: '/auth/hmac',
        headers: {
          'x-key-id': MockAuthDemo.hmacKeyId,
          'x-timestamp': ts,
          'x-nonce': 'n3',
          'x-signature': sig,
        },
        query: const {},
      )!;
      expect(ok.statusCode, 200);

      final replay = auth.handle(
        method: 'GET',
        path: '/auth/hmac',
        headers: {
          'x-key-id': MockAuthDemo.hmacKeyId,
          'x-timestamp': ts,
          'x-nonce': 'n3',
          'x-signature': sig,
        },
        query: const {},
      )!;
      expect(replay.statusCode, 401);
      expect(replay.body['reason'], 'replay');
    });
  });

  test('rate-limited returns 429', () {
    final result = MockAuthHandler().handle(
      method: 'GET',
      path: '/auth/rate-limited',
      headers: const {},
      query: const {},
    )!;
    expect(result.statusCode, 429);
    expect(result.headers['retry-after'], '1');
    expect(result.body['reason'], 'too_many_requests');
  });

  test('unknown auth path is not handled', () {
    expect(
      MockAuthHandler().handle(
        method: 'GET',
        path: '/auth/other',
        headers: const {},
        query: const {},
      ),
      isNull,
    );
  });
}
