// Pattern 095: JsonToModel
// JSON を強型付き Dart クラスに変換。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern095Controller extends BaseController {
  final _service = Pattern095Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
