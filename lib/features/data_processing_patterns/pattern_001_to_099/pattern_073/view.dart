// Pattern 073: CacheEviction
// キャッシュ立ち退き (Eviction) 実装。
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controller.dart';

class Pattern073View extends GetView<Pattern073Controller> {
  const Pattern073View({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pattern 073: CacheEviction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'キャッシュ立ち退き (Eviction) 実装。',
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
