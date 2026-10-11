import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/data_processing/inherited_catalogue_example.dart';

class Pattern160View extends StatelessWidget {
  const Pattern160View({super.key});

  @override
  Widget build(BuildContext context) => const InheritedCatalogueExample(
    title: 'Pattern 160: InheritedWidget',
    description: 'InheritedWidget による状態伝播。',
    selective: false,
  );
}
