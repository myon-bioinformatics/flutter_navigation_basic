// Pattern 012: NestedNavigator
// 子 Navigator を持つ Nested ナビゲーション。
import 'model.dart';

class Pattern012Service {
  Future<Pattern012Result> run() async {
    // TODO: 実装を追加してください
    await Future.delayed(const Duration(milliseconds: 100));
    return Pattern012Result(message: 'NestedNavigator executed successfully');
  }
}
