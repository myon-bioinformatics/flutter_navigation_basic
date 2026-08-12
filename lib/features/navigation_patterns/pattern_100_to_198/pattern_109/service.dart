// Pattern 109: PopWithData
// Pop 時にデータを返す実装。
import 'model.dart';

class Pattern109Service {
  Future<Pattern109Result> run() async {
    // TODO: 実装を追加してください
    await Future.delayed(const Duration(milliseconds: 100));
    return Pattern109Result(message: 'PopWithData executed successfully');
  }
}
