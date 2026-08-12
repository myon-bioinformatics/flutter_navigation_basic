// Pattern 078: NavigationRailExtended
// 拡張表示対応 NavigationRail。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern078Controller extends BaseController {
  final _service = Pattern078Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
