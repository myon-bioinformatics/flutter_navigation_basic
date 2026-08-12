// Pattern 121: FutureBasic
// 基本的な Future と async/await 実装。
import 'model.dart';

class Pattern121Service {
  Future<Pattern121Result> run() async {
    // TODO: 実装を追加してください
    await Future.delayed(const Duration(milliseconds: 100));
    return Pattern121Result(message: 'FutureBasic executed successfully');
  }
}
