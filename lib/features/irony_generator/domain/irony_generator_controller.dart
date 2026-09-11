import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../config.dart';

class IronyGeneratorController extends ChangeNotifier {
  IronyGeneratorController({Random? random}) : _random = random ?? Random() {
    _irony = _randomIrony();
  }

  final Random _random;
  late String _irony;

  String get irony => _irony;

  void generateNext() {
    final ironies = Ironies.ironicList;
    if (ironies.length < 2) return;

    final currentIndex = ironies.indexOf(_irony);
    var nextIndex = _random.nextInt(ironies.length - 1);
    if (currentIndex >= 0 && nextIndex >= currentIndex) {
      nextIndex += 1;
    }
    _irony = ironies[nextIndex];
    notifyListeners();
  }

  String _randomIrony() {
    final ironies = Ironies.ironicList;
    return ironies[_random.nextInt(ironies.length)];
  }
}
