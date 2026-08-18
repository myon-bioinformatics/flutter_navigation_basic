import 'package:flutter/material.dart';
import '../domain/screen5_controller.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../shared/display/display_scope.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../core/utils/url_params.dart';

class Screen5Page extends StatelessWidget {
  const Screen5Page({super.key, required this.controller});

  final Screen5Controller controller;

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    return Scaffold(
      appBar: CustomAppBar(title: display.text('urlParameters.title')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: controller.cases.length,
              itemBuilder: (context, index) {
                final c = controller.cases[index];
                return _CaseTile(c: c);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomButton(
                  label: display.text('urlParameters.goHome'),
                  onPressed: AppNavigation.toHome,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CaseTile extends StatelessWidget {
  const _CaseTile({required this.c});

  final UrlParamCase c;

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              display.text('urlParameters.case', arguments: {'id': c.id, 'title': c.title}),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(display.text('urlParameters.route', arguments: {'route': c.route}),
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text(display.text('urlParameters.example', arguments: {'example': c.example}),
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                c.getter,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.indigo,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
