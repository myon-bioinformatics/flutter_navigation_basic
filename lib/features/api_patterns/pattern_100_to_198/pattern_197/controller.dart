// Pattern 197: ResponsiveImage
// 画面サイズに応じた画像の切り替え表示。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern197Controller extends BaseController {
  final _service = Pattern197Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
