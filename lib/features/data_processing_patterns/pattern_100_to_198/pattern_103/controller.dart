// Pattern 103: DataNormalize
// データ正規化 (文字列トリム、大文字小文字統一等)。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern103Controller extends BaseController {
  final _service = Pattern103Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
