// Pattern 097: JsonDiff
// 2つの JSON オブジェクトの差分比較。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern097Controller extends BaseController {
  final _service = Pattern097Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
