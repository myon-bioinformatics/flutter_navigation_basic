// Pattern 141: CancelableOp
// キャンセル可能な非同期操作実装。
import 'model.dart';

class Pattern141Service {
  Future<Pattern141Result> run() async {
    // TODO: 実装を追加してください
    await Future.delayed(const Duration(milliseconds: 100));
    return Pattern141Result(message: 'CancelableOp executed successfully');
  }
}
