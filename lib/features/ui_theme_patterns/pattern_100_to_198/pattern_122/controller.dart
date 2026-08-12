// Pattern 122: BreakPoint
// ブレークポイント定義とウィジェット切り替え。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern122Controller extends BaseController {
  final _service = Pattern122Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
