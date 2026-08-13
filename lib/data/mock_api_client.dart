import 'package:get/get.dart';

class MockApiClient extends GetConnect {
  MockApiClient({String? baseUrl}) {
    httpClient.baseUrl = baseUrl ?? defaultBaseUrl;
    httpClient.timeout = const Duration(seconds: 10);
  }

  static const String defaultBaseUrl = String.fromEnvironment(
    'MOCK_API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  Future<Response<Map<String, dynamic>>> fetchHealth() {
    return get<Map<String, dynamic>>('/api/health');
  }

  Future<Response<Map<String, dynamic>>> fetchUser1() {
    return get<Map<String, dynamic>>('/api/users/1');
  }
}
