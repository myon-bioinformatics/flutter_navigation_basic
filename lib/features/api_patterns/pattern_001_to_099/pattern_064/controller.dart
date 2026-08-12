// Pattern 064: WebSocketReconnect
// 切断時の自動再接続ロジック。
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
