import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../domain/composition_generator_controller.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/custom_button.dart';

class CompositionGeneratorPage extends GetView<CompositionGeneratorController> {
  const CompositionGeneratorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Composition Generator 🎸'),
      body: Obx(() => Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    controller.displayText,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      CustomButton(label: 'Home 🏠', onPressed: AppNavigation.toHome),
                      CustomButton(
                        label: 'Counter Playground 👾',
                        onPressed: AppNavigation.toCounterPlayground,
                      ),
                      CustomButton(
                        label: 'Irony Generator 🥐',
                        onPressed: AppNavigation.toIronyGenerator,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )),
    );
  }
}
