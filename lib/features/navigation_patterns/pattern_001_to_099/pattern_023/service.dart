// Pattern 023: NamedRouteResult
// Named Route の遷移結果を受け取る。
import 'model.dart';

class Pattern023Service {
  Future<Pattern023Result> run() async {
    // TODO: 実装を追加してください
    await Future.delayed(const Duration(milliseconds: 100));
    return Pattern023Result(message: 'NamedRouteResult executed successfully');
  }
}
