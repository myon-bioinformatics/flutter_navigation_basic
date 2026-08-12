// Pattern 002: HttpPost
// JSON ボディ付き HTTP POST リクエスト。
import 'dart:convert';
import 'dart:io';
import 'model.dart';

class Pattern002Service {
  /// JSON ボディ付き HTTP POST リクエスト (dart:io の HttpClient を使用)
  Future<Pattern002Result> run({
    Map<String, dynamic> body = const {'title': 'foo', 'body': 'bar', 'userId': 1},
  }) async {
    const url = 'https://httpbin.org/post';
    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse(url));
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.write(jsonEncode(body));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      return Pattern002Result(
        message: 'POST $url → ${response.statusCode}',
        statusCode: response.statusCode,
        echo: (json['json'] as Map<String, dynamic>?) ?? {},
      );
    } on SocketException catch (e) {
      return Pattern002Result(
        message: '接続エラー: ${e.message}',
        statusCode: 0,
        echo: {},
      );
    } finally {
      client.close();
    }
  }
}
