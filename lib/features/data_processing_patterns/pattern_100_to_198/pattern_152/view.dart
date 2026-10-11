import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/data_processing/native_state_catalogue_example.dart';

class Pattern152View extends StatelessWidget {
  const Pattern152View({super.key});

  @override
  Widget build(BuildContext context) => const NativeStateCatalogueExample(
    title: 'Pattern 152: GetxObservable',
    legacyDescription: 'Rx 変数による Observable 状態管理。',
  );
}
