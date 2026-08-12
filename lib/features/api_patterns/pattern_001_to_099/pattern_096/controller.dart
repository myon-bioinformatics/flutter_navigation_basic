// Pattern 096: ModelToJson
// Dart クラスを JSON 文字列に直列化。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern096Controller extends BaseController {
  final _service = Pattern096Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
