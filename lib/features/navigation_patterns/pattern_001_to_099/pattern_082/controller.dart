// Pattern 082: RoleBasedNav
// ロールに応じて表示画面を切り替え。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern082Controller extends BaseController {
  final _service = Pattern082Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
