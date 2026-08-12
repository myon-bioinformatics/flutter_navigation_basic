// Pattern 029: Timeout
// タイムアウト付き HTTP リクエスト基本形。
import 'model.dart';

class Pattern029Service {
  Future<Pattern029Result> run() async {
    // TODO: 実装を追加してください
    await Future.delayed(const Duration(milliseconds: 100));
    return Pattern029Result(message: 'Timeout executed successfully');
  }
}
