import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/counter_playground/domain/counter_playground_controller.dart';

void main() {
  group('CounterPlaygroundController', () {
    late CounterPlaygroundController controller;

    setUp(() {
      controller = CounterPlaygroundController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('initial counter is 0', () {
      expect(controller.counter, equals(0));
    });

    test('increment increases counter', () {
      controller.increment();
      expect(controller.counter, equals(1));
    });

    test('isTooMuch is false below 10', () {
      expect(controller.isTooMuch, isFalse);
    });

    test('isTooMuch is true at 10', () {
      for (var i = 0; i < 10; i++) {
        controller.increment();
      }
      expect(controller.isTooMuch, isTrue);
    });
  });
}
