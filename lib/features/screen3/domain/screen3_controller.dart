import 'dart:math';
import 'package:get/get.dart';
import '../../../core/services/base_controller.dart';
import '../../../config.dart';

class Screen3Controller extends BaseController {
  final RxString irony = Ironies.ironicList[Random().nextInt(5)].obs;
}
