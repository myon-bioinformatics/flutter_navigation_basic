// Pattern 011: WillPopScope
// WillPopScope で遷移キャンセルを制御。
import 'model.dart';

class Pattern011Service {
  Future<Pattern011Result> run() async {
    // TODO: 実装を追加してください
    await Future.delayed(const Duration(milliseconds: 100));
    return Pattern011Result(message: 'WillPopScope executed successfully');
  }
}
