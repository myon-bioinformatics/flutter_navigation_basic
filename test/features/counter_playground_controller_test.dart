import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/counter_playground/domain/counter_playground_controller.dart';

void main() {
  test('controller is the source of truth for step, history, and undo', () {
    final controller = CounterPlaygroundController();

    controller.setStep(5);
    controller.increment();
    expect(controller.counter, 5);
    expect(controller.history, [5, 0]);

    controller.decrement();
    expect(controller.counter, 0);
    expect(controller.canUndo, isTrue);

    controller.undo();
    expect(controller.counter, 5);

    controller.restore(2);
    expect(controller.counter, 2);

    controller.reset();
    expect(controller.counter, 0);
    controller.dispose();
  });
}
