// Pattern 007: SearchHighlight
// Python producer owns the limited processing contract; no fake GetX action.
import 'package:flutter/material.dart';
class Pattern007View extends StatelessWidget {
  const Pattern007View({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 007: SearchHighlight')),
    body: const Padding(padding: EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text('Python側に highlight 処理があります。'), SizedBox(height: 12),
        Text('Flutter画面からの実行・結果表示は未接続です。')],
    )),
  );
}
