class AppException implements Exception {
  const AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  final String message;
  final String? code;
  final Object? originalError;
  final StackTrace? stackTrace;

  @override
  String toString() =>
      'AppException(code: $code, message: $message)';
}

class NavigationException extends AppException {
  const NavigationException({required super.message, super.code, super.originalError});
}

class StorageException extends AppException {
  const StorageException({required super.message, super.code, super.originalError});
}

class ConfigException extends AppException {
  const ConfigException({required super.message, super.code, super.originalError});
}
