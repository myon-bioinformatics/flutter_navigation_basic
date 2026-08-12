import 'package:get/get.dart';
import '../logging/logger_service.dart';
import '../exceptions/error_handler.dart';

abstract class BaseController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool hasError = false.obs;

  String get controllerName => runtimeType.toString();

  @override
  void onInit() {
    super.onInit();
    LoggerService.debug('$controllerName initialized');
  }

  @override
  void onClose() {
    LoggerService.debug('$controllerName closed');
    super.onClose();
  }

  Future<void> runAsync(Future<void> Function() action) async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';
      await action();
    } catch (e, st) {
      ErrorHandler.handle(e, st);
      hasError.value = true;
      errorMessage.value = ErrorHandler.wrap(e, st).message;
    } finally {
      isLoading.value = false;
    }
  }
}
