// Pattern 008: JsonParse
// レスポンス JSON を Dart オブジェクトへ変換。
import 'model.dart';

class Pattern008Service {
  Future<Pattern008Result> run() async {
    // TODO: 実装を追加してください
    await Future.delayed(const Duration(milliseconds: 100));
    return Pattern008Result(message: 'JsonParse executed successfully');
  }
}
