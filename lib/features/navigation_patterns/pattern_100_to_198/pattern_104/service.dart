// Pattern 104: HomeToRoot
// どの画面からもホームへ戻るショートカット。
import 'model.dart';

class Pattern104Service {
  Future<Pattern104Result> run() async {
    // TODO: 実装を追加してください
    await Future.delayed(const Duration(milliseconds: 100));
    return Pattern104Result(message: 'HomeToRoot executed successfully');
  }
}
