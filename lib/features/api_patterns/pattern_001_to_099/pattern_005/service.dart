// Pattern 005: HttpPatch
// 部分更新の PATCH リクエスト。
import 'model.dart';

class Pattern005Service {
  Future<Pattern005Result> run() async {
    // TODO: 実装を追加してください
    await Future.delayed(const Duration(milliseconds: 100));
    return Pattern005Result(message: 'HttpPatch executed successfully');
  }
}
