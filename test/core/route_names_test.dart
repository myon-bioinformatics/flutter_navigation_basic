import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/navigation/route_names.dart';

void main() {
  group('RouteNames', () {
    test('home route is /', () {
      expect(RouteNames.home, equals('/'));
    });

    test('counter playground keeps canonical /screen2 path', () {
      expect(RouteNames.counterPlayground, equals('/screen2'));
    });

    test('irony generator keeps canonical /screen3 path', () {
      expect(RouteNames.ironyGenerator, equals('/screen3'));
    });

    test('composition generator keeps canonical /screen4 path', () {
      expect(RouteNames.compositionGenerator, equals('/screen4'));
    });
  });
}
