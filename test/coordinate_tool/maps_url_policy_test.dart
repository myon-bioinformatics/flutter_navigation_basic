import 'package:flutter_application_1/features/coordinate_tool/domain/maps_url_expander_io.dart';
import 'package:flutter_application_1/features/coordinate_tool/domain/maps_url_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MapsUrlPolicy', () {
    test('blocks localhost / private / link-local hosts', () {
      expect(MapsUrlPolicy.isBlockedNetworkHost('127.0.0.1'), isTrue);
      expect(MapsUrlPolicy.isBlockedNetworkHost('localhost'), isTrue);
      expect(MapsUrlPolicy.isBlockedNetworkHost('192.168.1.10'), isTrue);
      expect(MapsUrlPolicy.isBlockedNetworkHost('10.0.0.2'), isTrue);
      expect(MapsUrlPolicy.isBlockedNetworkHost('169.254.1.1'), isTrue);
      expect(MapsUrlPolicy.isBlockedNetworkHost('::1'), isTrue);
      expect(MapsUrlPolicy.isBlockedNetworkHost('www.google.com'), isFalse);
    });

    test('short share allow-list is Maps-scoped', () {
      expect(
        MapsUrlPolicy.isAllowedShortShareUri(
          Uri.parse('https://maps.app.goo.gl/abc'),
        ),
        isTrue,
      );
      expect(
        MapsUrlPolicy.isAllowedShortShareUri(
          Uri.parse('https://goo.gl/maps/abc'),
        ),
        isTrue,
      );
      expect(
        MapsUrlPolicy.isAllowedShortShareUri(Uri.parse('https://goo.gl/abc')),
        isFalse,
      );
      expect(
        MapsUrlPolicy.isAllowedShortShareUri(
          Uri.parse('https://g.co/not-maps'),
        ),
        isFalse,
      );
    });

    test('expanded Maps allow-list rejects arbitrary q= hosts', () {
      expect(
        MapsUrlPolicy.isAllowedExpandedMapsUri(
          Uri.parse(
            'https://www.google.com/maps/@35.681236,139.767125,16z',
          ),
        ),
        isTrue,
      );
      expect(
        MapsUrlPolicy.isAllowedExpandedMapsUri(
          Uri.parse('https://maps.apple.com/?ll=35.6,139.7'),
        ),
        isTrue,
      );
      expect(
        MapsUrlPolicy.isAllowedExpandedMapsUri(
          Uri.parse('https://example.com/?q=35.0,139.0'),
        ),
        isFalse,
      );
      expect(
        MapsUrlPolicy.isAllowedExpandedMapsUri(
          Uri.parse('http://127.0.0.1/?q=35.0,139.0'),
        ),
        isFalse,
      );
    });
  });

  group('expandMapsShareUrl manual redirects', () {
    test('follows allowed hop and returns final Google Maps URI', () async {
      final requested = <Uri>[];
      final start = Uri.parse('https://maps.app.goo.gl/tokyoDemo');
      final finalUri = Uri.parse(
        'https://www.google.com/maps/place/Tokyo/@35.681236,139.767125,17z',
      );

      final resolved = await expandMapsShareUrl(
        start,
        fetch: (uri) async {
          requested.add(uri);
          if (uri == start) {
            return MapsRedirectHop(statusCode: 302, location: finalUri);
          }
          return const MapsRedirectHop(statusCode: 200);
        },
      );

      expect(resolved, finalUri);
      expect(requested, [start, finalUri]);
    });

    test('does not GET a blocked second hop', () async {
      final requested = <Uri>[];
      final start = Uri.parse('https://maps.app.goo.gl/ssrfDemo');
      final blocked = Uri.parse('http://127.0.0.1:8080/admin');

      await expectLater(
        () => expandMapsShareUrl(
          start,
          fetch: (uri) async {
            requested.add(uri);
            if (uri == start) {
              return MapsRedirectHop(statusCode: 302, location: blocked);
            }
            return const MapsRedirectHop(statusCode: 200);
          },
        ),
        throwsA(isA<StateError>()),
      );

      expect(requested, [start]);
      expect(requested, isNot(contains(blocked)));
    });

    test('resolves relative Location against the current hop', () async {
      final requested = <Uri>[];
      final start = Uri.parse('https://maps.app.goo.gl/relDemo');
      final mid = Uri.parse('https://www.google.com/maps/');
      final expected = Uri.parse('https://www.google.com/maps/@35.0,139.0,16z');

      final resolved = await expandMapsShareUrl(
        start,
        fetch: (uri) async {
          requested.add(uri);
          if (uri == start) {
            return MapsRedirectHop(statusCode: 302, location: mid);
          }
          if (uri == mid) {
            return MapsRedirectHop(
              statusCode: 302,
              location: Uri.parse('/maps/@35.0,139.0,16z'),
            );
          }
          if (uri == expected) {
            return const MapsRedirectHop(statusCode: 200);
          }
          fail('unexpected hop $uri');
        },
      );

      expect(resolved, expected);
      expect(requested, [start, mid, expected]);
    });

    test('enforces redirect hop limit', () async {
      var n = 0;
      final start = Uri.parse('https://maps.app.goo.gl/loopDemo');
      await expectLater(
        () => expandMapsShareUrl(
          start,
          maxRedirects: 2,
          fetch: (uri) async {
            n += 1;
            return MapsRedirectHop(
              statusCode: 302,
              location: Uri.parse('https://www.google.com/maps/hop-$n'),
            );
          },
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Too many'),
          ),
        ),
      );
    });
  });
}
