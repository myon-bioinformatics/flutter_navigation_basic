// Pattern 125: Fallback
// エラー時のフォールバック値返却。
import 'model.dart';

class Pattern125Service {
  Future<Pattern125Result> run() async {
    // TODO: 実装を追加してください
    await Future.delayed(const Duration(milliseconds: 100));
    return Pattern125Result(message: 'Fallback executed successfully');
  }
}
