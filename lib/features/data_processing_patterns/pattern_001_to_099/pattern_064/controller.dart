// Pattern 064: WeakRefCache
// 弱参照を使ったキャッシュ実装 (擬似)。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern064Controller extends BaseController {
  final _service = Pattern064Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
