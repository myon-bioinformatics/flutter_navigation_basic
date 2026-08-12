// Pattern 005: HttpPatch
// 部分更新の PATCH リクエスト。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern005Controller extends BaseController {
  final _service = Pattern005Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
