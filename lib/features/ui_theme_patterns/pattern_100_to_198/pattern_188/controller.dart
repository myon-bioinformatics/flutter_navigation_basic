// Pattern 188: BoldText
// 太字テキスト設定の検出と対応。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern188Controller extends BaseController {
  final _service = Pattern188Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
