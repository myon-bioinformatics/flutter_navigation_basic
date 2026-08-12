// Pattern 135: FoldableLayout
// 折り畳みデバイス対応レイアウト (擬似)。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern135Controller extends BaseController {
  final _service = Pattern135Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
