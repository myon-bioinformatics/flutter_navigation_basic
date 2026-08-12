// Pattern 007: PopUntil
// 指定ルートが見つかるまで Pop を繰り返す。
import 'model.dart';

class Pattern007Service {
  Future<Pattern007Result> run() async {
    // TODO: 実装を追加してください
    await Future.delayed(const Duration(milliseconds: 100));
    return Pattern007Result(message: 'PopUntil executed successfully');
  }
}
