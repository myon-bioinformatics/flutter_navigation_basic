import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:isolate';

int _sumSquares(List<int> values) =>
    values.fold<int>(0, (sum, value) => sum + value * value);

/// Pattern 136 uses an isolate on native platforms. Web has no equivalent
/// guarantee, so it reports its fallback explicitly rather than claiming
/// background parallelism.
class NativeParallelPatternExample extends StatefulWidget {
  const NativeParallelPatternExample({super.key, required this.patternId});
  final int patternId;

  @override
  State<NativeParallelPatternExample> createState() =>
      _NativeParallelPatternExampleState();
}

class _NativeParallelPatternExampleState
    extends State<NativeParallelPatternExample> {
  String _status = '未実行';
  bool _running = false;

  Future<void> _execute() async {
    if (_running) return;
    setState(() {
      _running = true;
      _status = '実行中';
    });
    try {
      const values = [1, 2, 3, 4, 5];
      final int result;
      final String engine;
      if (widget.patternId == 136) {
        if (kIsWeb) {
          result = _sumSquares(values);
          engine = 'Web同期フォールバック（Isolate並列実行なし）';
        } else {
          result = await Isolate.run(() => _sumSquares(values));
          engine = 'Isolate.run';
        }
      } else if (widget.patternId == 137) {
        result = await compute(_sumSquares, values);
        engine = kIsWeb ? 'compute（Webでは別Isolate保証なし）' : 'compute';
      } else {
        throw ArgumentError.value(widget.patternId, 'patternId');
      }
      if (mounted) setState(() => _status = '$engine: $result');
    } catch (error) {
      if (mounted) setState(() => _status = '失敗: $error');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Pattern ${widget.patternId}')),
        body: Column(
          children: [
            Text(_status, key: const ValueKey('parallel-status')),
            ElevatedButton(
              onPressed: _running ? null : _execute,
              child: const Text('実行'),
            ),
          ],
        ),
      );
}
