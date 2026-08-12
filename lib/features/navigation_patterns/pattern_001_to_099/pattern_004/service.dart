// Pattern 004: PushWithResult
// 遷移先から結果を受け取る Push & Return値。
import 'model.dart';

class Pattern004Service {
  Future<Pattern004Result> run() async {
    // TODO: 実装を追加してください
    await Future.delayed(const Duration(milliseconds: 100));
    return Pattern004Result(message: 'PushWithResult executed successfully');
  }
}
