import 'package:flutter/material.dart';
import '../config/routes.dart';
import '../widgets/nav_button.dart';

class CounterPlaygroundScreen extends StatefulWidget {
  const CounterPlaygroundScreen({super.key});

  @override
  State<CounterPlaygroundScreen> createState() => _CounterPlaygroundScreenState();
}

class _CounterPlaygroundScreenState extends State<CounterPlaygroundScreen> {
  static const int _min = -100;
  static const int _max = 100;

  var _counter = 0;
  var _step = 1;
  final List<int> _history = <int>[0];

  void _changeCounter(int delta) {
    final next = (_counter + delta).clamp(_min, _max);
    if (next == _counter) return;
    setState(() {
      _counter = next;
      _history.insert(0, _counter);
      if (_history.length > 8) _history.removeLast();
    });
  }

  void _reset() {
    setState(() {
      _counter = 0;
      _history
        ..clear()
        ..add(0);
    });
  }

  String get _status {
    if (_counter == _max) return 'Maximum reached 🚀';
    if (_counter == _min) return 'Minimum reached 🧊';
    if (_counter >= 50) return 'High score territory 🔥';
    if (_counter <= -50) return 'Going underground 🕳️';
    if (_counter >= 10) return 'Too much 😈';
    if (_counter <= -10) return 'Reverse mode 👻';
    return 'Keep experimenting 👾';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter Playground 👾'),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text('Current value'),
                        const SizedBox(height: 8),
                        Semantics(
                          label: 'Counter value $_counter',
                          liveRegion: true,
                          child: Text(
                            '$_counter',
                            style: theme.textTheme.displayMedium,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(_status, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 20),
                        SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(value: 1, label: Text('Step 1')),
                            ButtonSegment(value: 5, label: Text('Step 5')),
                            ButtonSegment(value: 10, label: Text('Step 10')),
                          ],
                          selected: {_step},
                          onSelectionChanged: (selection) {
                            setState(() => _step = selection.first);
                          },
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            FilledButton.icon(
                              onPressed: _counter > _min
                                  ? () => _changeCounter(-_step)
                                  : null,
                              icon: const Icon(Icons.remove),
                              label: const Text('Decrease'),
                            ),
                            FilledButton.icon(
                              onPressed: _counter < _max
                                  ? () => _changeCounter(_step)
                                  : null,
                              icon: const Icon(Icons.add),
                              label: const Text('Increase'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _counter == 0 ? null : _reset,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reset'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Recent values', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _history
                              .map((value) => Chip(label: Text('$value')))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    NavButton(label: 'Home 🏠', routeName: AppRoutes.home),
                    NavButton(label: 'Irony Generator 🥐', routeName: AppRoutes.ironyGenerator),
                    NavButton(label: 'Composition Generator 🎸', routeName: AppRoutes.compositionGenerator),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
