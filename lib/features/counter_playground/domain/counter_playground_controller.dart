import 'package:flutter/foundation.dart';

import 'counter_battle_effect.dart';

class CounterPlaygroundController extends ChangeNotifier {
  static const int min = -100;
  static const int max = 100;

  int _counter = 0;
  int _burstToken = 0;

  int get counter => _counter;
  int get burstToken => _burstToken;
  bool get isTooMuch => _counter >= 10;
  CounterBattleEffect get battleEffect =>
      CounterBattleEffect.fromCounter(_counter);

  void increment() => changeBy(1);

  void decrement() => changeBy(-1);

  void changeBy(int delta) {
    final next = (_counter + delta).clamp(min, max);
    if (next == _counter) return;
    _counter = next;
    _burstToken++;
    notifyListeners();
  }

  void reset() {
    if (_counter == 0) return;
    _counter = 0;
    _burstToken++;
    notifyListeners();
  }
}
