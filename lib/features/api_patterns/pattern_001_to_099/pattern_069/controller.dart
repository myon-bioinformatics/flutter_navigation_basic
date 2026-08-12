// Pattern 069: WebSocketAuth
// WebSocket 接続時の認証トークン付与。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern069Controller extends BaseController {
  final _service = Pattern069Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
