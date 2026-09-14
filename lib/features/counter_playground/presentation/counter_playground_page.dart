import 'package:flutter/material.dart';

import '../../../core/navigation/route_names.dart';
import '../../../shared/display/display_scope.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/hold_repeating_button.dart';
import '../../../shared/widgets/tool_door_selector.dart';
import '../domain/counter_playground_controller.dart';
import 'counter_orb_burst.dart';

class CounterPlaygroundPage extends StatefulWidget {
  const CounterPlaygroundPage({super.key, required this.controller});

  final CounterPlaygroundController controller;

  @override
  State<CounterPlaygroundPage> createState() => _CounterPlaygroundPageState();
}

class _CounterPlaygroundPageState extends State<CounterPlaygroundPage> {
  CounterPlaygroundController get _controller => widget.controller;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _status(DisplayController display) {
    final counter = _controller.counter;
    if (counter == CounterPlaygroundController.max) {
      return display.text('counterLegacy.statusMax');
    }
    if (counter == CounterPlaygroundController.min) {
      return display.text('counterLegacy.statusMin');
    }
    if (counter >= 50) return display.text('counterLegacy.statusHigh');
    if (counter <= -50) return display.text('counterLegacy.statusLow');
    if (counter >= 10) return display.text('counterLegacy.statusTooMuch');
    if (counter <= -10) return display.text('counterLegacy.statusReverse');
    return display.text('counterLegacy.statusNeutral');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final display = DisplayScope.of(context);
    return Scaffold(
      appBar: CustomAppBar(title: display.text('nav.counterPlayground')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 72),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                final counter = _controller.counter;
                final step = _controller.step;
                final history = _controller.history;
                final effect = _controller.battleEffect;
                return Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Text(display.text('counterLegacy.currentValue')),
                            const SizedBox(height: 8),
                            Semantics(
                              label: display.text(
                                'counterLegacy.currentValue',
                              ),
                              value: '$counter',
                              liveRegion: true,
                              child: ExcludeSemantics(
                                child: Text(
                                  '$counter',
                                  style: theme.textTheme.displayMedium,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            CounterOrbBurst(
                              effect: effect,
                              playToken: _controller.burstToken,
                              damageLabel: display.text(
                                'counter.battleDamage',
                                arguments: {'amount': effect.amount},
                              ),
                              healLabel: display.text(
                                'counter.battleHeal',
                                arguments: {'amount': effect.amount},
                              ),
                              idleLabel: display.text('counter.battleIdle'),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _status(display),
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 20),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SegmentedButton<int>(
                                segments: [
                                  ButtonSegment(
                                    value: 1,
                                    label: Text(
                                      display.text('counterLegacy.step1'),
                                    ),
                                  ),
                                  ButtonSegment(
                                    value: 5,
                                    label: Text(
                                      display.text('counterLegacy.step5'),
                                    ),
                                  ),
                                  ButtonSegment(
                                    value: 10,
                                    label: Text(
                                      display.text('counterLegacy.step10'),
                                    ),
                                  ),
                                ],
                                selected: {step},
                                onSelectionChanged: (selection) {
                                  _controller.setStep(selection.first);
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                HoldRepeatingButton(
                                  onPressed: counter >
                                          CounterPlaygroundController.min
                                      ? _controller.decrement
                                      : null,
                                  icon: const Icon(Icons.remove),
                                  label: Text(
                                    display.text('counterLegacy.decrease'),
                                  ),
                                ),
                                HoldRepeatingButton(
                                  onPressed: counter <
                                          CounterPlaygroundController.max
                                      ? _controller.increment
                                      : null,
                                  icon: const Icon(Icons.add),
                                  label: Text(
                                    display.text('counterLegacy.increase'),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed:
                                      counter == 0 ? null : _controller.reset,
                                  icon: const Icon(Icons.refresh),
                                  label: Text(
                                    display.text('counterLegacy.reset'),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _controller.canUndo
                                      ? _controller.undo
                                      : null,
                                  icon: const Icon(Icons.undo),
                                  label: Text(
                                    display.text('counterLegacy.undo'),
                                  ),
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
                            Text(
                              display.text('counterLegacy.recentValues'),
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              display.text('counterLegacy.tapToRestore'),
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: history
                                  .asMap()
                                  .entries
                                  .map(
                                    (entry) => ActionChip(
                                      tooltip: entry.key == 0
                                          ? display.text(
                                              'counterLegacy.currentValue',
                                            )
                                          : display.text(
                                              'counterLegacy.restoreTooltip',
                                              arguments: {
                                                'value': entry.value,
                                              },
                                            ),
                                      onPressed: entry.key == 0
                                          ? null
                                          : () => _controller.restore(
                                                entry.value,
                                              ),
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
                    const ToolDoorSelector(
                      currentRouteName: RouteNames.counterPlayground,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
