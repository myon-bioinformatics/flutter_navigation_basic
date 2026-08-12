// Pattern 006: PushNamed
// ルート名文字列で遷移する Named Push。
import 'model.dart';

class Pattern006Service {
  Future<Pattern006Result> run() async {
    // TODO: 実装を追加してください
    await Future.delayed(const Duration(milliseconds: 100));
    return Pattern006Result(message: 'PushNamed executed successfully');
  }
}
