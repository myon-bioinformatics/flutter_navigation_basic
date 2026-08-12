// Pattern 025: Accept
// Accept ヘッダーによるレスポンス形式指定。
import 'model.dart';

class Pattern025Service {
  Future<Pattern025Result> run() async {
    // TODO: 実装を追加してください
    await Future.delayed(const Duration(milliseconds: 100));
    return Pattern025Result(message: 'Accept executed successfully');
  }
}
