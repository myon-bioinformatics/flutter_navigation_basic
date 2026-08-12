// Pattern 005: PushAndRemoveUntil
// 指定条件まで全スタックをクリアして遷移。
import 'model.dart';

class Pattern005Service {
  Future<Pattern005Result> run() async {
    // TODO: 実装を追加してください
    await Future.delayed(const Duration(milliseconds: 100));
    return Pattern005Result(message: 'PushAndRemoveUntil executed successfully');
  }
}
