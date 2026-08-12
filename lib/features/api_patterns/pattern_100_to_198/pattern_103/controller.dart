// Pattern 103: YamlRead
// YAML 文字列のパース (標準ライブラリ範囲)。
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
