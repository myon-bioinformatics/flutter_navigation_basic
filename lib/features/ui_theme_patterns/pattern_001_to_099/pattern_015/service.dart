// Pattern 015: ProgressIndicator
// LinearProgressIndicator / CircularProgressIndicator。
import 'model.dart';

class Pattern015Service {
  Future<Pattern015Result> run() async {
    // TODO: 実装を追加してください
    await Future.delayed(const Duration(milliseconds: 100));
    return Pattern015Result(message: 'ProgressIndicator executed successfully');
  }
}
