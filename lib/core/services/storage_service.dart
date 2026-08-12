import 'package:shared_preferences/shared_preferences.dart';
import '../exceptions/app_exception.dart';
import '../logging/logger_service.dart';

class StorageService {
  StorageService._();

  static SharedPreferences? _prefs;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    LoggerService.debug('StorageService initialized');
  }

  static Future<bool> setString(String key, String value) async {
    try {
      if (_prefs == null) throw StorageException(message: 'StorageService not initialized');
      return await _prefs!.setString(key, value);
    } on StorageException {
      rethrow;
    } catch (e) {
      throw StorageException(message: 'Failed to save key "$key"', originalError: e);
    }
  }

  static String? getString(String key) => _prefs?.getString(key);

  static Future<bool> setBool(String key, bool value) async {
    try {
      if (_prefs == null) throw StorageException(message: 'StorageService not initialized');
      return await _prefs!.setBool(key, value);
    } on StorageException {
      rethrow;
    } catch (e) {
      throw StorageException(message: 'Failed to save key "$key"', originalError: e);
    }
  }

  static bool? getBool(String key) => _prefs?.getBool(key);

  static Future<bool> remove(String key) async {
    try {
      if (_prefs == null) throw StorageException(message: 'StorageService not initialized');
      return await _prefs!.remove(key);
    } on StorageException {
      rethrow;
    } catch (e) {
      throw StorageException(message: 'Failed to remove key "$key"', originalError: e);
    }
  }

  static Future<bool> clear() async {
    try {
      if (_prefs == null) throw StorageException(message: 'StorageService not initialized');
      return await _prefs!.clear();
    } on StorageException {
      rethrow;
    } catch (e) {
      throw StorageException(message: 'Failed to clear storage', originalError: e);
    }
  }
}
