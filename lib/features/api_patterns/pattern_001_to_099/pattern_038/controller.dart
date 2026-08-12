// Pattern 038: OAuth2Implicit
// OAuth2 暗黙フロー (擬似実装)。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern038Controller extends BaseController {
  final _service = Pattern038Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
