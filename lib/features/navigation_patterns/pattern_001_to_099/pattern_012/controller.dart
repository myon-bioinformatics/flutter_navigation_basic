// Pattern 012: NestedNavigator
// 子 Navigator を持つ Nested ナビゲーション。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern012Controller extends BaseController {
  final _service = Pattern012Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
