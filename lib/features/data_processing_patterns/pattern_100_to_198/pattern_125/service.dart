// Pattern 125: FutureAny
// Future.any による最速レスポンス取得。
import 'model.dart';

class Pattern125Service {
  Future<Pattern125Result> run() async {
    // TODO: 実装を追加してください
    await Future.delayed(const Duration(milliseconds: 100));
    return Pattern125Result(message: 'FutureAny executed successfully');
  }
}
