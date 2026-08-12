// Pattern 140: PopScopeNested
// ネスト Navigator での PopScope 制御。
import 'model.dart';

class Pattern140Service {
  Future<Pattern140Result> run() async {
    // TODO: 実装を追加してください
    await Future.delayed(const Duration(milliseconds: 100));
    return Pattern140Result(message: 'PopScopeNested executed successfully');
  }
}
