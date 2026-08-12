import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../domain/screen3_controller.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/custom_button.dart';

class Screen3Page extends GetView<Screen3Controller> {
  const Screen3Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Irony(Screen 3🥐)'),
      body: Obx(() => Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    controller.irony.value,
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
                    label: 'Go to Screen 4🎸',
                    onPressed: AppNavigation.toScreen4,
                  ),
                ],
              ),
            ],
          )),
    );
  }
}
