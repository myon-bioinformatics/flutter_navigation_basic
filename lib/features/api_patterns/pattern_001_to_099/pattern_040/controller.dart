// Pattern 040: ApiKeyQuery
// API Key をクエリパラメータで送信。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern040Controller extends BaseController {
  final _service = Pattern040Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
