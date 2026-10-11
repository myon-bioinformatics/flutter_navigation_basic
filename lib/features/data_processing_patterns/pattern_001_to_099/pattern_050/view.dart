import 'package:flutter/material.dart';

class Pattern050View extends StatelessWidget {
  const Pattern050View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 050: ThumbnailList')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('サムネイル付きリスト実装。'),
    ),
  );
}
