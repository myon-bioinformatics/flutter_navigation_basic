// Pattern 185: PositionSwap
// 指定位置間でのアイテム入れ替え。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern185Controller extends BaseController {
  final _service = Pattern185Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
