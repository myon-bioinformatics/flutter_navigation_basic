// Pattern 002: BasicPop
// スタックから現在画面を取り除く Pop 遷移。
import 'model.dart';

class Pattern002Service {
  Future<Pattern002Result> run() async {
    // TODO: 実装を追加してください
    await Future.delayed(const Duration(milliseconds: 100));
    return Pattern002Result(message: 'BasicPop executed successfully');
  }
}
