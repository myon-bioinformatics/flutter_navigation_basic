import '../logging/logger_service.dart';
import 'app_exception.dart';

class ErrorHandler {
  ErrorHandler._();

  static void handle(Object error, [StackTrace? stackTrace]) {
    if (error is AppException) {
      LoggerService.error(
        error.message,
        error: error.originalError,
        stackTrace: stackTrace ?? error.stackTrace,
      );
    } else {
      LoggerService.error(
        'Unhandled error: $error',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static AppException wrap(Object error, [StackTrace? stackTrace]) {
    if (error is AppException) return error;
    return AppException(
      message: error.toString(),
      originalError: error,
      stackTrace: stackTrace,
    );
  }
}
