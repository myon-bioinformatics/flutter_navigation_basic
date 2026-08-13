import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/navigation/route_names.dart';

void main() {
  group('RouteNames', () {
    test('home route is /', () {
      expect(RouteNames.home, equals('/'));
    });

    test('counter playground uses a semantic example path', () {
      expect(RouteNames.counterPlayground, equals('/examples/counter-playground'));
    });

    test('irony generator uses a semantic example path', () {
      expect(RouteNames.ironyGenerator, equals('/examples/irony-generator'));
    });

    test('composition generator uses a semantic example path', () {
      expect(
        RouteNames.compositionGenerator,
        equals('/examples/composition-generator'),
      );
    });
  });
}
