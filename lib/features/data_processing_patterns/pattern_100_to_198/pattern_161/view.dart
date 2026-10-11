import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/data_processing/inherited_catalogue_example.dart';

class Pattern161View extends StatelessWidget {
  const Pattern161View({super.key});

  @override
  Widget build(BuildContext context) => const InheritedCatalogueExample(
    title: 'Pattern 161: InheritedModel',
    description: 'InheritedModel による選択的再ビルド。',
    selective: true,
  );
}
