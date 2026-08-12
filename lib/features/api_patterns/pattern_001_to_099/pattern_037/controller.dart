// Pattern 037: OAuth2Code
// OAuth2 認可コードフロー (擬似実装)。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern037Controller extends BaseController {
  final _service = Pattern037Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
