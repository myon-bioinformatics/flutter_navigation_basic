// Pattern 009: JsonSerialize
// Dart オブジェクトを JSON に変換して送信。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern009Controller extends BaseController {
  final _service = Pattern009Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
