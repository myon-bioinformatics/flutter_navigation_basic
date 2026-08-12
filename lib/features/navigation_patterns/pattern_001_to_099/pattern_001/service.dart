// Pattern 001: BasicPush
// 最も基本的な画面プッシュ遷移。Navigator.push/Get.to。
import 'model.dart';

class Pattern001Service {
  Future<Pattern001Result> run() async {
    // TODO: 実装を追加してください
    await Future.delayed(const Duration(milliseconds: 100));
    return Pattern001Result(message: 'BasicPush executed successfully');
  }
}
