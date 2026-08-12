// Pattern 017: HeroAnimation
// Hero ウィジェットを使ったシェアードエレメント遷移。
import 'model.dart';

class Pattern017Service {
  Future<Pattern017Result> run() async {
    // TODO: 実装を追加してください
    await Future.delayed(const Duration(milliseconds: 100));
    return Pattern017Result(message: 'HeroAnimation executed successfully');
  }
}
