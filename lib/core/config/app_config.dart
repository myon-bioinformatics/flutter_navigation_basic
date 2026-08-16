enum AppEnvironment { development, production }

class AppConfig {
  AppConfig._();

  static AppEnvironment _environment = AppEnvironment.development;

  static AppEnvironment get environment => _environment;

  static bool get isDevelopment => _environment == AppEnvironment.development;
  static bool get isProduction => _environment == AppEnvironment.production;

  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'FlutterNavigationBasic',
  );

  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.example.com',
  );

  static const String logLevel = String.fromEnvironment(
    'LOG_LEVEL',
    defaultValue: 'debug',
  );

  static Future<void> initialize({
    AppEnvironment env = AppEnvironment.development,
  }) async {
    _environment = env;
  }
}
