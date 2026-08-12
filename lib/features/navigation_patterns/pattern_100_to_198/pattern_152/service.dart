// Pattern 152: ChainedAnimation
// 複数アニメーションを連鎖実行。
import 'model.dart';

class Pattern152Service {
  Future<Pattern152Result> run() async {
    // TODO: 実装を追加してください
    await Future.delayed(const Duration(milliseconds: 100));
    return Pattern152Result(message: 'ChainedAnimation executed successfully');
  }
}
