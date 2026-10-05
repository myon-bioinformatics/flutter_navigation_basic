import 'package:flutter/material.dart';

import 'json_list_asset.dart';

/// Display boundary for externally processed examples, not a runtime filter.
/// One local state replaces per-pattern GetX controllers and message models.
class ProcessedListExample extends StatefulWidget {
  const ProcessedListExample({super.key, required this.title, required this.asset});

  final String title;
  final JsonListAsset asset;

  @override
  State<ProcessedListExample> createState() => _ProcessedListExampleState();
}

class _ProcessedListExampleState extends State<ProcessedListExample> {
  bool _loading = false;
  List<dynamic>? _values;
  String? _error;

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _values = null;
      _error = null;
    });
    try {
      final values = await widget.asset.load();
      if (!mounted) return;
      setState(() => _values = values);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pythonで生成した処理結果を読み込む例。'),
            const SizedBox(height: 16),
            if (_loading)
              const Text('状態: 実行中...')
            else if (_error != null) ...[
              const Text('状態: 読み込み失敗'),
              Text(_error!),
            ] else if (_values != null)
              Text('結果: $_values')
            else
              const Text('状態: 待機中'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _load,
              child: const Text('実行'),
            ),
          ],
        ),
      ),
    );
  }
}
