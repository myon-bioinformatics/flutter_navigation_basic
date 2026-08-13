import 'package:get/get.dart';

class MockApiClient extends GetConnect {
  MockApiClient({String? baseUrl}) {
    httpClient.baseUrl = baseUrl ?? defaultBaseUrl;
    httpClient.timeout = const Duration(seconds: 10);
  }

  static const String defaultBaseUrl = String.fromEnvironment(
    'MOCK_API_BASE_URL',
    defaultValue: 'https://myon-bioinformatics.github.io/mock_server_JS',
  );

  Future<Response<Map<String, dynamic>>> fetchHealth() {
    return get<Map<String, dynamic>>('/api/health/');
  }

  Future<Response<Map<String, dynamic>>> fetchUser1() {
    return get<Map<String, dynamic>>('/api/users/1/');
  }

  Future<Map<String, dynamic>> fetchScenario(
    String group,
    String scenario,
  ) async {
    final response = await get<Map<String, dynamic>>('/scenarios.json');
    if (!response.isOk || response.body == null) {
      throw StateError(
        'Could not load scenario fixtures (HTTP ${response.statusCode}).',
      );
    }

    final groupData = response.body![group];
    if (groupData is! Map) {
      throw StateError('Scenario group not found: $group');
    }

    final scenarioData = groupData[scenario];
    if (scenarioData is! Map) {
      throw StateError('Scenario not found: $group.$scenario');
    }

    return Map<String, dynamic>.from(scenarioData);
  }
}
