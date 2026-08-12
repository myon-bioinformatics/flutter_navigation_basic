// Pattern 121: ErrorHandlingBasic
// HTTP エラーコードに応じた例外処理。
import 'model.dart';

class Pattern121Service {
  Future<Pattern121Result> run() async {
    // TODO: 実装を追加してください
    await Future.delayed(const Duration(milliseconds: 100));
    return Pattern121Result(message: 'ErrorHandlingBasic executed successfully');
  }
}
