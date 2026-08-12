// Pattern 151: HttpCacheBasic
// 基本的な HTTP キャッシュ実装。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern151Controller extends BaseController {
  final _service = Pattern151Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
