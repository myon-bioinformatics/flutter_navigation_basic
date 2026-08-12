// Pattern 040: CupertinoAction
// CupertinoActionSheet の実装。
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controller.dart';

class Pattern040View extends GetView<Pattern040Controller> {
  const Pattern040View({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pattern 040: CupertinoAction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CupertinoActionSheet の実装。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Obx(() => Text('状態: ${controller.status.value}')),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: controller.execute,
              child: const Text('実行'),
            ),
          ],
        ),
      ),
    );
  }
}
