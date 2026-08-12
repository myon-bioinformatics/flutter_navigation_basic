// Pattern 021: HttpHead
// HEAD リクエストでメタ情報確認。
import 'model.dart';

class Pattern021Service {
  Future<Pattern021Result> run() async {
    // TODO: 実装を追加してください
    await Future.delayed(const Duration(milliseconds: 100));
    return Pattern021Result(message: 'HttpHead executed successfully');
  }
}
