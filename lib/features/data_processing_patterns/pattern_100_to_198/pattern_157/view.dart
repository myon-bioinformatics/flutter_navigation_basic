import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/data_processing/inherited_catalogue_example.dart';

/// Provider-like propagation using Flutter's own InheritedWidget, not provider.
class Pattern157View extends StatelessWidget {
  const Pattern157View({super.key});

  @override
  Widget build(BuildContext context) => const InheritedCatalogueExample(
    title: 'Pattern 157: ProviderBasic',
    description: 'Provider パターンによる状態管理 (擬似実装)。',
    selective: false,
  );
}
