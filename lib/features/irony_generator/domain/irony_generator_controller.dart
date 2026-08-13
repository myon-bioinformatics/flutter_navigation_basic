import 'dart:math';
import 'package:get/get.dart';
import '../../../core/services/base_controller.dart';
import '../../../config.dart';

class IronyGeneratorController extends BaseController {
  final RxString irony =
      Ironies.ironicList[Random().nextInt(Ironies.ironicList.length)].obs;
}
