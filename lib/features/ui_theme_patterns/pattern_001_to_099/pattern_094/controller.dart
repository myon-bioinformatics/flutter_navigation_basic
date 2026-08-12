// Pattern 094: DarkModeIcon
// ダークモードに応じたアイコン切り替え。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern094Controller extends BaseController {
  final _service = Pattern094Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
