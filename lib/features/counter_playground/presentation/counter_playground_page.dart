import 'package:flutter/material.dart';
import '../domain/counter_playground_controller.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/custom_button.dart';

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
    return Scaffold(
      appBar: const CustomAppBar(title: 'Counter Playground 👾'),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, child) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                '${widget.controller.counter}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              Text(
                widget.controller.isTooMuch ? 'Too much 😈' : '',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 20),
              FloatingActionButton(
                onPressed: widget.controller.increment,
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  CustomButton(label: 'Home 🏠', onPressed: AppNavigation.toHome),
                  CustomButton(
                    label: 'Irony Generator 🥐',
                    onPressed: AppNavigation.toIronyGenerator,
                  ),
                  CustomButton(
                    label: 'Composition Generator 🎸',
                    onPressed: AppNavigation.toCompositionGenerator,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
