// Pattern 148: Idempotency
// 冪等性キーを使ったリトライ安全実装。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern148Controller extends BaseController {
  final _service = Pattern148Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
