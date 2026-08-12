// Pattern 003: HttpPut
// リソース全体更新の PUT リクエスト。
import 'model.dart';

class Pattern003Service {
  Future<Pattern003Result> run() async {
    // TODO: 実装を追加してください
    await Future.delayed(const Duration(milliseconds: 100));
    return Pattern003Result(message: 'HttpPut executed successfully');
  }
}
