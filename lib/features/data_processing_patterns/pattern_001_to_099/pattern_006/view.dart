// Pattern 006: SearchFuzzy
// Python producer owns the limited processing contract; no fake GetX action.
import 'package:flutter/material.dart';
class Pattern006View extends StatelessWidget {
  const Pattern006View({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 006: SearchFuzzy')),
    body: const Padding(padding: EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text('Python側に fuzzy 処理があります。'), SizedBox(height: 12),
        Text('Flutter画面からの実行・結果表示は未接続です。')],
    )),
  );
}
