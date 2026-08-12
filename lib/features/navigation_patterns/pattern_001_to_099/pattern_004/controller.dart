// Pattern 004: PushWithResult
// 遷移先から結果を受け取る Push & Return値。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern004Controller extends BaseController {
  final _service = Pattern004Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
