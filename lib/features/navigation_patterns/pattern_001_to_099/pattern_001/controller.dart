// Pattern 001: BasicPush
// 最も基本的な画面プッシュ遷移。Navigator.push/Get.to。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern001Controller extends BaseController {
  final _service = Pattern001Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
