import 'package:flutter/material.dart';

/// Minimal native Flutter state demo replacing fake GetX completion shells.
/// Does not emulate GetX bindings, workers, services, or dependency injection.
class NativeStateCatalogueExample extends StatefulWidget {
  const NativeStateCatalogueExample({
    super.key,
    required this.title,
    required this.legacyDescription,
  });

  final String title;
  final String legacyDescription;

  @override
  State<NativeStateCatalogueExample> createState() => _NativeStateCatalogueExampleState();
}

class _NativeStateCatalogueExampleState extends State<NativeStateCatalogueExample> {
  final ValueNotifier<int> _count = ValueNotifier<int>(0);

  @override
  void dispose() {
    _count.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.legacyDescription),
          const SizedBox(height: 12),
          const Text('GetXを使用しないFlutter標準のValueNotifier実例。旧GetX固有機能の同等実装ではありません。'),
          const SizedBox(height: 16),
          ValueListenableBuilder<int>(
            valueListenable: _count,
            builder: (context, value, child) => Text('カウント: $value'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => _count.value++, child: const Text('加算')),
          TextButton(onPressed: () => _count.value = 0, child: const Text('リセット')),
        ],
      ),
    ),
  );
}
