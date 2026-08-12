// Pattern 009: JsonSerialize
// Dart オブジェクトを JSON に変換して送信。
import 'model.dart';

class Pattern009Service {
  Future<Pattern009Result> run() async {
    // TODO: 実装を追加してください
    await Future.delayed(const Duration(milliseconds: 100));
    return Pattern009Result(message: 'JsonSerialize executed successfully');
  }
}
