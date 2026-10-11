// Pattern 031: PaginationBasic
// Real processing is owned by Python; the Flutter runtime bridge is pending.
import 'package:flutter/material.dart';

class Pattern031View extends StatelessWidget {
  const Pattern031View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 031: PaginationBasic')),
    body: const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('オフセット方式のページ取得はPython側で実装済みです。'),
          SizedBox(height: 12),
          Text('Flutter画面からの実行・結果表示は未接続です。'),
        ],
      ),
    ),
  );
}
