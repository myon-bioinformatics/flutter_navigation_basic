// Pattern 060: DeepLinkLocalized
// 多言語ロケール付きディープリンク。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern060Controller extends BaseController {
  final _service = Pattern060Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
