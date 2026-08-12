// Pattern 067: AnimatedTheme
// テーマ切り替えアニメーション実装。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern067Controller extends BaseController {
  final _service = Pattern067Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
