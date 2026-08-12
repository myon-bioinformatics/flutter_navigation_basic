import 'package:flutter_dotenv/flutter_dotenv.dart';

enum AppEnvironment { development, production }

class AppConfig {
  AppConfig._();

  static AppEnvironment _environment = AppEnvironment.development;

  static AppEnvironment get environment => _environment;

  static bool get isDevelopment => _environment == AppEnvironment.development;
  static bool get isProduction => _environment == AppEnvironment.production;

  static String get appName =>
      dotenv.env['APP_NAME'] ?? 'FlutterNavigationBasic';

  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';

  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://api.example.com';

  static String get logLevel => dotenv.env['LOG_LEVEL'] ?? 'debug';

  static Future<void> initialize({
    AppEnvironment env = AppEnvironment.development,
  }) async {
    _environment = env;
    final envFile = env == AppEnvironment.production ? '.env.prod' : '.env.dev';
    await dotenv.load(fileName: envFile);
  }
}
