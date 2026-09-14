import 'package:flutter/foundation.dart';

import 'counter_battle_effect.dart';

/// Source of truth for Counter Playground value, step, history, and burst token.
class CounterPlaygroundController extends ChangeNotifier {
  static const int min = -100;
  static const int max = 100;

  int _counter = 0;
  int _step = 1;
  int _burstToken = 0;
  final List<int> _history = <int>[0];

  int get counter => _counter;
  int get step => _step;
  int get burstToken => _burstToken;
  List<int> get history => List<int>.unmodifiable(_history);
  bool get canUndo => _history.length > 1;
  bool get isTooMuch => _counter >= 10;
  CounterBattleEffect get battleEffect =>
      CounterBattleEffect.fromCounter(_counter);

  void setStep(int value) {
    if (value != 1 && value != 5 && value != 10) return;
    if (value == _step) return;
    _step = value;
    notifyListeners();
  }

  void increment() => changeBy(_step);

  void decrement() => changeBy(-_step);

  void changeBy(int delta) {
    final next = (_counter + delta).clamp(min, max);
    if (next == _counter) return;
    _counter = next;
    _burstToken++;
    _record(_counter);
    notifyListeners();
  }

  void restore(int value) {
    final next = value.clamp(min, max);
    if (next == _counter) return;
    _counter = next;
    _burstToken++;
    _record(_counter);
    notifyListeners();
  }

  void undo() {
    if (!canUndo) return;
    _history.removeAt(0);
    _counter = _history.first;
    _burstToken++;
    notifyListeners();
  }

  void reset() {
    if (_counter == 0) return;
    _counter = 0;
    _burstToken++;
    _record(0);
    notifyListeners();
  }

  void _record(int value) {
    _history.insert(0, value);
    if (_history.length > 8) _history.removeLast();
  }
}
