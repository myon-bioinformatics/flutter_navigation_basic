// Pattern 022: NamedRouteArguments
// Named Route に引数を渡す実装。
import 'model.dart';

class Pattern022Service {
  Future<Pattern022Result> run() async {
    // TODO: 実装を追加してください
    await Future.delayed(const Duration(milliseconds: 100));
    return Pattern022Result(message: 'NamedRouteArguments executed successfully');
  }
}
