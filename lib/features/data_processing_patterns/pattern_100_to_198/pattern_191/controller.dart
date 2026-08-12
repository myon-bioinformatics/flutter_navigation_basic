// Pattern 191: Saga
// Saga パターンによる分散トランザクション (擬似)。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern191Controller extends BaseController {
  final _service = Pattern191Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
