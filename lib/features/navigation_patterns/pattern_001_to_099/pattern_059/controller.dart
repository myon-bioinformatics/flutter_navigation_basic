// Pattern 059: DeepLinkAnalytics
// ディープリンク遷移をアナリティクス送信。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern059Controller extends BaseController {
  final _service = Pattern059Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
