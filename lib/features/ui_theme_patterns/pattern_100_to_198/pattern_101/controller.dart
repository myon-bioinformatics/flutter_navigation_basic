// Pattern 101: ScheduledTheme
// 時刻に応じて自動切り替えするテーマ。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern101Controller extends BaseController {
  final _service = Pattern101Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
