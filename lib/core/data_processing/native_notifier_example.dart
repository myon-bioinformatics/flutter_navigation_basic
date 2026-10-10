import 'package:flutter/material.dart';

class _CounterChangeNotifier extends ChangeNotifier {
  int count = 0;
  void increment() { count++; notifyListeners(); }
  void reset() { count = 0; notifyListeners(); }
}

/// An actual Flutter notification demo, not a Provider/GetX replacement.
class NativeNotifierExample extends StatefulWidget {
  const NativeNotifierExample({super.key, required this.title, required this.description,
    required this.useChangeNotifier});
  final String title;
  final String description;
  final bool useChangeNotifier;
  @override State<NativeNotifierExample> createState() => _NativeNotifierExampleState();
}

class _NativeNotifierExampleState extends State<NativeNotifierExample> {
  final _change = _CounterChangeNotifier();
  final _value = ValueNotifier<int>(0);
  @override void dispose() { _change.dispose(); _value.dispose(); super.dispose(); }
  void _increment() {
    if (widget.useChangeNotifier) { _change.increment(); } else { _value.value++; }
  }
  void _reset() {
    if (widget.useChangeNotifier) { _change.reset(); } else { _value.value = 0; }
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: Padding(padding: const EdgeInsets.all(16),child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.description),
        const SizedBox(height: 12),
        Text(widget.useChangeNotifier ? 'ChangeNotifierで状態を通知' : 'ValueNotifierで状態を通知'),
        const SizedBox(height: 12),
        ListenableBuilder(
          listenable: widget.useChangeNotifier ? _change : _value,
          builder: (context, child) => Text('カウント: ${widget.useChangeNotifier ? _change.count : _value.value}'),
        ),
        ElevatedButton(onPressed: _increment, child: const Text('加算')),
        TextButton(onPressed: _reset, child: const Text('リセット')),
      ],
    )),
  );
}
