// Pattern 173: DisplayMode
// 高リフレッシュレート対応 (擬似実装)。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern173Controller extends BaseController {
  final _service = Pattern173Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
