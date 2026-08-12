// Pattern 085: DataCompression
// データ圧縮 (gzip 相当、擬似実装)。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern085Controller extends BaseController {
  final _service = Pattern085Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
