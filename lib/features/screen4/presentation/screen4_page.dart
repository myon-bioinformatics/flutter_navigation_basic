import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../domain/screen4_controller.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/custom_button.dart';

class Screen4Page extends GetView<Screen4Controller> {
  const Screen4Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Composion(Screen 4🎸)'),
      body: Obx(() => Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    controller.displayText,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomButton(
                    label: 'Go to HomeApp🏠',
                    onPressed: AppNavigation.toHome,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomButton(
                    label: 'Go to Screen 2👾',
                    onPressed: AppNavigation.toScreen2,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomButton(
                    label: 'Go to Screen 3🥐',
                    onPressed: AppNavigation.toScreen3,
                  ),
                ],
              ),
            ],
          )),
    );
  }
}
