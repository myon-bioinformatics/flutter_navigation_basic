// Pattern 126: FutureTimeout
// Future.timeout によるタイムアウト制御。
import 'model.dart';

class Pattern126Service {
  Future<Pattern126Result> run() async {
    // TODO: 実装を追加してください
    await Future.delayed(const Duration(milliseconds: 100));
    return Pattern126Result(message: 'FutureTimeout executed successfully');
  }
}
