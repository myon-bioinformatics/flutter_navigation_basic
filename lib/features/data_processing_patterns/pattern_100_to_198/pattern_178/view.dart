import 'package:flutter/material.dart';

class Pattern178View extends StatelessWidget {
  const Pattern178View({super.key});
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 178: MoveToBottom')),
    body: const Padding(padding: EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,children: [
        Text('アイテムをリスト末尾に移動。'), SizedBox(height: 12),
        Text('Python CLIに参照処理あり。Flutterでの実行接続は未実装。'),
      ],
    )),
  );
}
