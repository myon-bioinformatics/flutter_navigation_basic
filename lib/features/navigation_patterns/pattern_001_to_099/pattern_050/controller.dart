// Pattern 050: DeepLinkBranch
// 条件分岐付きディープリンク処理。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern050Controller extends BaseController {
  final _service = Pattern050Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
