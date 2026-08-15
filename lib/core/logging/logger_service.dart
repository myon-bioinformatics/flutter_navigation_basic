import 'dart:developer' as developer;

import '../config/app_config.dart';

class LoggerService {
  LoggerService._();

  static const String _name = 'flutter_navigation_basic';

  static int get _minimumLevel {
    switch (AppConfig.logLevel) {
      case 'info':
        return 800;
      case 'warning':
        return 900;
      case 'error':
        return 1000;
      case 'debug':
      default:
        return AppConfig.isProduction ? 1000 : 500;
    }
  }

  static void _write(
    int level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level < _minimumLevel) return;
    developer.log(
      message,
      name: _name,
      level: level,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void debug(String message, {Object? error, StackTrace? stackTrace}) =>
      _write(500, message, error: error, stackTrace: stackTrace);

  static void info(String message, {Object? error, StackTrace? stackTrace}) =>
      _write(800, message, error: error, stackTrace: stackTrace);

  static void warning(String message, {Object? error, StackTrace? stackTrace}) =>
      _write(900, message, error: error, stackTrace: stackTrace);

  static void error(String message, {Object? error, StackTrace? stackTrace}) =>
      _write(1000, message, error: error, stackTrace: stackTrace);
}
