// Pattern 196: WidgetToRoute
// ウィジェット状態をルート引数として渡す。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern196Controller extends BaseController {
  final _service = Pattern196Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
