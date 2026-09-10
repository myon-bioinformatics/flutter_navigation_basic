import 'package:flutter/material.dart';
import '../domain/counter_playground_controller.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../shared/display/display_scope.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/hold_repeating_button.dart';
import 'counter_orb_burst.dart';

class CounterPlaygroundPage extends StatefulWidget {
  const CounterPlaygroundPage({super.key, required this.controller});

  final CounterPlaygroundController controller;

  @override
  State<CounterPlaygroundPage> createState() => _CounterPlaygroundPageState();
}

class _CounterPlaygroundPageState extends State<CounterPlaygroundPage> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    return Scaffold(
      appBar: CustomAppBar(title: display.text('nav.counterPlayground')),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, child) {
          final effect = widget.controller.battleEffect;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  '${widget.controller.counter}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                CounterOrbBurst(
                  effect: effect,
                  playToken: widget.controller.burstToken,
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
                const SizedBox(height: 12),
                Text(
                  widget.controller.isTooMuch
                      ? display.text('counter.tooMuch')
                      : '',
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    HoldRepeatingButton(
                      onPressed: widget.controller.counter >
                              CounterPlaygroundController.min
                          ? widget.controller.decrement
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    HoldRepeatingButton(
                      onPressed: widget.controller.counter <
                              CounterPlaygroundController.max
                          ? widget.controller.increment
                          : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    CustomButton(
                      label: display.text('home.title'),
                      onPressed: AppNavigation.toHome,
                    ),
                    CustomButton(
                      label: display.text('nav.ironyGenerator'),
                      onPressed: AppNavigation.toIronyGenerator,
                    ),
                    CustomButton(
                      label: display.text('nav.compositionGenerator'),
                      onPressed: AppNavigation.toCompositionGenerator,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
