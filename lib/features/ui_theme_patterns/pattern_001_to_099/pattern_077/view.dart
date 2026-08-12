// Pattern 077: NatureTheme
// 自然インスパイアテーマ実装。
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controller.dart';

class Pattern077View extends GetView<Pattern077Controller> {
  const Pattern077View({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pattern 077: NatureTheme'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '自然インスパイアテーマ実装。',
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
