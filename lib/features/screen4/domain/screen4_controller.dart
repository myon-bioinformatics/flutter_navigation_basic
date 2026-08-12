import 'dart:math';
import 'package:get/get.dart';
import '../../../core/services/base_controller.dart';
import '../../../config.dart';

class Screen4Controller extends BaseController {
  final RxString tonicKey = Composer.diatonicScaleList[Random().nextInt(12)].obs;
  final RxInt bpm = (100 + Random().nextInt(61)).obs;

  String get displayText => 'Key: ${tonicKey.value}, BPM: ${bpm.value}';
}
