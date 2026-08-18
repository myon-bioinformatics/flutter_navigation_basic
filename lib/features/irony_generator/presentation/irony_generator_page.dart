import 'package:flutter/material.dart';
import '../domain/irony_generator_controller.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../shared/display/display_scope.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/custom_button.dart';

class IronyGeneratorPage extends StatelessWidget {
  const IronyGeneratorPage({super.key, required this.controller});

  final IronyGeneratorController controller;

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    return Scaffold(
      appBar: CustomAppBar(title: display.text('nav.ironyGenerator')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                controller.irony,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  CustomButton(label: display.text('home.title'), onPressed: AppNavigation.toHome),
                  CustomButton(
                    label: display.text('nav.counterPlayground'),
                    onPressed: AppNavigation.toCounterPlayground,
                  ),
                  CustomButton(
                    label: display.text('nav.compositionGenerator'),
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
