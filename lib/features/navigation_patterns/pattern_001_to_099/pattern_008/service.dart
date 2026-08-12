// Pattern 008: OffAll
// 全スタックを破棄して新しいルートへ。
import 'model.dart';

class Pattern008Service {
  Future<Pattern008Result> run() async {
    // TODO: 実装を追加してください
    await Future.delayed(const Duration(milliseconds: 100));
    return Pattern008Result(message: 'OffAll executed successfully');
  }
}
