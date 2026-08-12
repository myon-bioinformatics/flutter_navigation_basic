// Pattern 190: AccessibilityInspect
// アクセシビリティ検査ツール表示 (擬似)。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern190Controller extends BaseController {
  final _service = Pattern190Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
