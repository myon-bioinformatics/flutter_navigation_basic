import 'package:logger/logger.dart';
import '../config/app_config.dart';

class LoggerService {
  LoggerService._();

  static Logger? _logger;

  static Logger get _instance {
    _logger ??= Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
      ),
      level: _resolveLevel(),
      output: ConsoleOutput(),
    );
    return _logger!;
  }

  static Level _resolveLevel() {
    switch (AppConfig.logLevel) {
      case 'debug':
        return Level.debug;
      case 'info':
        return Level.info;
      case 'warning':
        return Level.warning;
      case 'error':
        return Level.error;
      default:
        return AppConfig.isProduction ? Level.error : Level.debug;
    }
  }

  static void debug(String message, {Object? error, StackTrace? stackTrace}) =>
      _instance.d(message, error: error, stackTrace: stackTrace);

  static void info(String message, {Object? error, StackTrace? stackTrace}) =>
      _instance.i(message, error: error, stackTrace: stackTrace);

  static void warning(String message, {Object? error, StackTrace? stackTrace}) =>
      _instance.w(message, error: error, stackTrace: stackTrace);

  static void error(String message, {Object? error, StackTrace? stackTrace}) =>
      _instance.e(message, error: error, stackTrace: stackTrace);
}
