// Pattern 001: HttpGet
// 基本的な HTTP GET リクエスト実装。
import 'dart:convert';
import 'dart:io';
import 'model.dart';

class Pattern001Service {
  /// シンプルな HTTP GET リクエスト実装 (dart:io の HttpClient を使用)
  Future<Pattern001Result> run() async {
    const url = 'https://httpbin.org/get';
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      return Pattern001Result(
        message: 'GET $url → ${response.statusCode}',
        statusCode: response.statusCode,
        body: json,
      );
    } on SocketException catch (e) {
      return Pattern001Result(
        message: '接続エラー: ${e.message}',
        statusCode: 0,
        body: {'error': e.message},
      );
    } finally {
      client.close();
    }
  }
}
