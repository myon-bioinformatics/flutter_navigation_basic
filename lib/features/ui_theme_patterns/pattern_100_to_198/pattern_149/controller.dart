// Pattern 149: AdaptiveFont
// 画面サイズに応じたフォントサイズ調整。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern149Controller extends BaseController {
  final _service = Pattern149Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
