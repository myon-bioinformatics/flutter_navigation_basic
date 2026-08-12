// Pattern 123: FutureError
// Future エラーハンドリング実装。
import 'model.dart';

class Pattern123Service {
  Future<Pattern123Result> run() async {
    // TODO: 実装を追加してください
    await Future.delayed(const Duration(milliseconds: 100));
    return Pattern123Result(message: 'FutureError executed successfully');
  }
}
