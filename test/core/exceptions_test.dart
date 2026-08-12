import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/exceptions/app_exception.dart';
import 'package:flutter_application_1/core/exceptions/error_handler.dart';

void main() {
  group('AppException', () {
    test('toString includes code and message', () {
      const e = AppException(message: 'test error', code: 'ERR_001');
      expect(e.toString(), contains('ERR_001'));
      expect(e.toString(), contains('test error'));
    });

    test('NavigationException is an AppException', () {
      const e = NavigationException(message: 'nav error');
      expect(e, isA<AppException>());
    });

    test('StorageException is an AppException', () {
      const e = StorageException(message: 'storage error');
      expect(e, isA<AppException>());
    });
  });

  group('ErrorHandler', () {
    test('wrap returns same AppException', () {
      const original = AppException(message: 'original');
      final wrapped = ErrorHandler.wrap(original);
      expect(wrapped, same(original));
    });

    test('wrap converts non-AppException to AppException', () {
      final error = Exception('raw error');
      final wrapped = ErrorHandler.wrap(error);
      expect(wrapped, isA<AppException>());
      expect(wrapped.originalError, equals(error));
    });
  });
}
