import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/navigation/route_names.dart';

void main() {
  group('RouteNames', () {
    test('home route is /', () {
      expect(RouteNames.home, equals('/'));
    });

    test('screen2 route is /screen2', () {
      expect(RouteNames.screen2, equals('/screen2'));
    });

    test('screen3 route is /screen3', () {
      expect(RouteNames.screen3, equals('/screen3'));
    });

    test('screen4 route is /screen4', () {
      expect(RouteNames.screen4, equals('/screen4'));
    });
  });
}
