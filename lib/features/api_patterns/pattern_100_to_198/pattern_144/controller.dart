// Pattern 144: OfflineMode
// オフライン時のキャッシュフォールバック。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern144Controller extends BaseController {
  final _service = Pattern144Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
