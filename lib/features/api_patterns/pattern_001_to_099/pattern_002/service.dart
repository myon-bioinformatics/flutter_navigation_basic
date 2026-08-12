// Pattern 002: HttpPost
// JSON ボディ付き HTTP POST リクエスト。
import 'model.dart';

class Pattern002Service {
  Future<Pattern002Result> run() async {
    // TODO: 実装を追加してください
    await Future.delayed(const Duration(milliseconds: 100));
    return Pattern002Result(message: 'HttpPost executed successfully');
  }
}
