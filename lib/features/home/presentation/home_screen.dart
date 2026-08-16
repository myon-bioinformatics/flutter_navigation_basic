import 'package:flutter/material.dart';
import '../domain/home_controller.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../shared/diagnostics/build_diagnostics_card.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/custom_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Home 🏠'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              controller.today,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            const BuildDiagnosticsCard(screenId: 'home'),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                CustomButton(
                  label: 'Counter Playground 👾',
                  onPressed: AppNavigation.toCounterPlayground,
                ),
                CustomButton(
                  label: 'Irony Generator 🥐',
                  onPressed: AppNavigation.toIronyGenerator,
                ),
                CustomButton(
                  label: 'Composition Generator 🎸',
                  onPressed: AppNavigation.toCompositionGenerator,
                ),
                CustomButton(
                  label: 'URL Params 🔗',
                  onPressed: AppNavigation.toScreen5,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
