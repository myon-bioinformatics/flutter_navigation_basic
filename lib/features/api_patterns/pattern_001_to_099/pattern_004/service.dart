// Pattern 004: HttpDelete
// リソース削除の DELETE リクエスト。
import 'model.dart';

class Pattern004Service {
  Future<Pattern004Result> run() async {
    // TODO: 実装を追加してください
    await Future.delayed(const Duration(milliseconds: 100));
    return Pattern004Result(message: 'HttpDelete executed successfully');
  }
}
