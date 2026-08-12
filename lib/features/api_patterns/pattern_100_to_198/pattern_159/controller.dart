// Pattern 159: StaleWhileRevalidate
// Stale-While-Revalidate パターン。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern159Controller extends BaseController {
  final _service = Pattern159Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
