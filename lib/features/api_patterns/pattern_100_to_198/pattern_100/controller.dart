// Pattern 100: JsonlParse
// JSONL (JSON Lines) 形式のストリームパース。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern100Controller extends BaseController {
  final _service = Pattern100Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
