// Pattern 117: JsonEncoding
// 文字エンコーディング対応 JSON 処理。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern117Controller extends BaseController {
  final _service = Pattern117Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
