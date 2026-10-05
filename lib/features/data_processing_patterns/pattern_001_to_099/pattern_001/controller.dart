// Pattern 001: FilterBasic — loading/result/error UI state only.
import 'package:get/get.dart';
import '../../../../core/services/base_controller.dart';
import 'service.dart';

class Pattern001Controller extends BaseController {
  Pattern001Controller({Pattern001Service? service})
      : _service = service ?? Pattern001Service();

  final Pattern001Service _service;
  final RxString status = '待機中'.obs;

  Future<void> execute() async {
    if (isLoading.value) return;
    await runAsync(() async {
      status.value = '実行中...';
      final result = await _service.run();
      status.value = result.message;
    });
    if (hasError.value) status.value = '読み込み失敗';
  }
}
