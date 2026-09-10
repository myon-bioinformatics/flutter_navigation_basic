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
      expect(controller.battleEffect.isIdle, isTrue);
    });

    test('increment increases counter and deals damage', () {
      controller.increment();
      expect(controller.counter, equals(1));
      expect(controller.battleEffect.isHeal, isFalse);
      expect(controller.battleEffect.amount, 1);
      expect(controller.burstToken, 1);
    });

    test('decrement below zero heals by absolute value', () {
      controller.decrement();
      expect(controller.counter, equals(-1));
      expect(controller.battleEffect.isHeal, isTrue);
      expect(controller.battleEffect.amount, 1);
    });

    test('isTooMuch is false below 10', () {
      expect(controller.isTooMuch, isFalse);
    });

    test('isTooMuch is true at 10', () {
      for (var i = 0; i < 10; i++) {
        controller.increment();
      }
      expect(controller.isTooMuch, isTrue);
      expect(controller.battleEffect.amount, 10);
    });

    test('reset clears battle effect', () {
      controller.changeBy(5);
      controller.reset();
      expect(controller.counter, 0);
      expect(controller.battleEffect.isIdle, isTrue);
    });

    test('clamps at max without changing burstToken', () {
      controller.changeBy(CounterPlaygroundController.max);
      final token = controller.burstToken;
      expect(controller.counter, CounterPlaygroundController.max);
      controller.increment();
      expect(controller.counter, CounterPlaygroundController.max);
      expect(controller.burstToken, token);
    });

    test('clamps at min without changing burstToken', () {
      controller.changeBy(CounterPlaygroundController.min);
      final token = controller.burstToken;
      expect(controller.counter, CounterPlaygroundController.min);
      controller.decrement();
      expect(controller.counter, CounterPlaygroundController.min);
      expect(controller.burstToken, token);
    });
  });
}
