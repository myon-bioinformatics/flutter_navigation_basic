import 'package:flutter/material.dart';
import '../config/routes.dart';
import '../shared/display/display_scope.dart';
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

  void _record(int value) {
    _history.insert(0, value);
    if (_history.length > 8) _history.removeLast();
  }

  void _changeCounter(int delta) {
    final int next = (_counter + delta).clamp(_min, _max).toInt();
    if (next == _counter) return;
    setState(() {
      _counter = next;
      _record(_counter);
    });
  }

  void _restoreValue(int value) {
    if (value == _counter) return;
    setState(() {
      _counter = value;
      _record(_counter);
    });
  }

  void _undo() {
    if (_history.length < 2) return;
    setState(() {
      _history.removeAt(0);
      _counter = _history.first;
    });
  }

  void _reset() {
    if (_counter == 0) return;
    setState(() {
      _counter = 0;
      _record(0);
    });
  }

  String _status(DisplayController display) {
    if (_counter == _max) return display.text('counterLegacy.statusMax');
    if (_counter == _min) return display.text('counterLegacy.statusMin');
    if (_counter >= 50) return display.text('counterLegacy.statusHigh');
    if (_counter <= -50) return display.text('counterLegacy.statusLow');
    if (_counter >= 10) return display.text('counterLegacy.statusTooMuch');
    if (_counter <= -10) return display.text('counterLegacy.statusReverse');
    return display.text('counterLegacy.statusNeutral');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final display = DisplayScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(display.text('nav.counterPlayground')),
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
                        Text(display.text('counterLegacy.currentValue')),
                        const SizedBox(height: 8),
                        Semantics(
                          label: 'Counter value $_counter',
                          liveRegion: true,
                          child: ExcludeSemantics(
                            child: Text(
                              '$_counter',
                              style: theme.textTheme.displayMedium,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(_status(display), style: theme.textTheme.titleMedium),
                        const SizedBox(height: 20),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SegmentedButton<int>(
                            segments: [
                              ButtonSegment(value: 1, label: Text(display.text('counterLegacy.step1'))),
                              ButtonSegment(value: 5, label: Text(display.text('counterLegacy.step5'))),
                              ButtonSegment(value: 10, label: Text(display.text('counterLegacy.step10'))),
                            ],
                            selected: {_step},
                            onSelectionChanged: (selection) {
                              setState(() => _step = selection.first);
                            },
                          ),
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
                              label: Text(display.text('counterLegacy.decrease')),
                            ),
                            FilledButton.icon(
                              onPressed: _counter < _max
                                  ? () => _changeCounter(_step)
                                  : null,
                              icon: const Icon(Icons.add),
                              label: Text(display.text('counterLegacy.increase')),
                            ),
                            OutlinedButton.icon(
                              onPressed: _counter == 0 ? null : _reset,
                              icon: const Icon(Icons.refresh),
                              label: Text(display.text('counterLegacy.reset')),
                            ),
                            OutlinedButton.icon(
                              onPressed: _history.length > 1 ? _undo : null,
                              icon: const Icon(Icons.undo),
                              label: Text(display.text('counterLegacy.undo')),
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
                        Text(display.text('counterLegacy.recentValues'), style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          display.text('counterLegacy.tapToRestore'),
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _history
                              .asMap()
                              .entries
                              .map(
                                (entry) => ActionChip(
                                  tooltip: entry.key == 0
                                      ? display.text('counterLegacy.currentValue')
                                      : display.text(
                                          'counterLegacy.restoreTooltip',
                                          arguments: {'value': entry.value},
                                        ),
                                  onPressed: entry.key == 0
                                      ? null
                                      : () => _restoreValue(entry.value),
                                  label: Text('${entry.value}'),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    NavButton(label: display.text('home.title'), routeName: AppRoutes.home),
                    NavButton(label: display.text('nav.ironyGenerator'), routeName: AppRoutes.ironyGenerator),
                    NavButton(label: display.text('nav.compositionGenerator'), routeName: AppRoutes.compositionGenerator),
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
