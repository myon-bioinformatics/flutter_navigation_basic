// Pattern 031: ApiKeyHeader
// API Key をヘッダーに付与して認証。
import 'model.dart';

class Pattern031Service {
  Future<Pattern031Result> run() async {
    // TODO: 実装を追加してください
    await Future.delayed(const Duration(milliseconds: 100));
    return Pattern031Result(message: 'ApiKeyHeader executed successfully');
  }
}
