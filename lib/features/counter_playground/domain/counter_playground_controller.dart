import 'package:flutter/foundation.dart';

class CounterPlaygroundController extends ChangeNotifier {
  int _counter = 0;

  int get counter => _counter;
  bool get isTooMuch => _counter >= 10;

  void increment() {
    _counter++;
    notifyListeners();
  }
}
