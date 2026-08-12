import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../domain/screen2_controller.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/custom_button.dart';

class Screen2Page extends GetView<Screen2Controller> {
  const Screen2Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Trick and Mock(Screen 2👾)'),
      body: Obx(() => Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${controller.counter.value}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                controller.isTooMuch ? 'Too much😈' : '',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton(
                    onPressed: controller.increment,
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomButton(label: 'mock 1🙂', onPressed: () {}),
                  const SizedBox(width: 20),
                  CustomButton(label: 'mock 2🙂', onPressed: () {}),
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
                    label: 'Go to Screen 3🥐',
                    onPressed: AppNavigation.toScreen3,
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
