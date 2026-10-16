import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get appName => dotenv.env['APP_NAME'] ?? 'KYC Onboarding';
  static String get appEnv => dotenv.env['APP_ENV'] ?? 'development';

  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';
  static int get apiConnectTimeout =>
      int.parse(dotenv.env['API_CONNECT_TIMEOUT'] ?? '30000');
  static int get apiReceiveTimeout =>
      int.parse(dotenv.env['API_RECEIVE_TIMEOUT'] ?? '60000');

  static bool get enableLogging => dotenv.env['ENABLE_LOGGING'] == 'true';
  static bool get enableAnalytics => dotenv.env['ENABLE_ANALYTICS'] == 'true';

  static bool get isDevelopment => appEnv == 'development';
  static bool get isProduction => appEnv == 'production';
  static bool get isStaging => appEnv == 'staging';
}
