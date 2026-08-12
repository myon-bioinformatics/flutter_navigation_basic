// Pattern 072: SeasonTheme
// 季節に応じたダイナミックテーマ。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern072Controller extends BaseController {
  final _service = Pattern072Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
