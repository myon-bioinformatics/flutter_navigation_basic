// Pattern 074: DrawerHeader
// ユーザー情報を表示する DrawerHeader。
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern074Controller extends BaseController {
  final _service = Pattern074Service();
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    await runAsync(() async {
      status.value = '実行中...';
      await _service.run();
      status.value = '完了';
    });
  }
}
