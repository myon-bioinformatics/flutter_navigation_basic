// Pattern 122: FutureChain
// Future のチェーン (.then) 実装。
import 'model.dart';

class Pattern122Service {
  Future<Pattern122Result> run() async {
    // TODO: 実装を追加してください
    await Future.delayed(const Duration(milliseconds: 100));
    return Pattern122Result(message: 'FutureChain executed successfully');
  }
}
