// Pattern 134: WebLayout
// Web 向けセンタリング+最大幅レイアウト。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern134Controller extends BaseController {
  final _service = Pattern134Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
