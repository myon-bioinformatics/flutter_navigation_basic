// Pattern 130: UserFriendlyError
// ユーザー向けエラーメッセージの表示。
import 'model.dart';

class Pattern130Service {
  Future<Pattern130Result> run() async {
    // TODO: 実装を追加してください
    await Future.delayed(const Duration(milliseconds: 100));
    return Pattern130Result(message: 'UserFriendlyError executed successfully');
  }
}
