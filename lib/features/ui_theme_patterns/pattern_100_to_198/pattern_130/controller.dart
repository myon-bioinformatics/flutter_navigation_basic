// Pattern 130: MediaQuery
// MediaQuery で画面情報を取得してレイアウト。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern130Controller extends BaseController {
  final _service = Pattern130Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
