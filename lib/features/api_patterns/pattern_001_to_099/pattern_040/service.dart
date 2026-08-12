// Pattern 040: ApiKeyQuery
// API Key をクエリパラメータで送信。
import 'model.dart';

class Pattern040Service {
  Future<Pattern040Result> run() async {
    // TODO: 実装を追加してください
    await Future.delayed(const Duration(milliseconds: 100));
    return Pattern040Result(message: 'ApiKeyQuery executed successfully');
  }
}
