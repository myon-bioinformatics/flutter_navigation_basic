// Pattern 178: ParallelDownload
// 複数ファイルの並列ダウンロード。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern178Controller extends BaseController {
  final _service = Pattern178Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
