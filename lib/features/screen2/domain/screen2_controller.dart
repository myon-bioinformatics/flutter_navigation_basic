import 'package:get/get.dart';
import '../../../core/services/base_controller.dart';

class Screen2Controller extends BaseController {
  final RxInt counter = 0.obs;

  bool get isTooMuch => counter.value >= 10;

  void increment() => counter.value++;
}
