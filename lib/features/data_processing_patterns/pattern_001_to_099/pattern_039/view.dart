// Pattern 039: PageIndicator — rendered Python state, no GetX controller.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/data_processing/processed_list_example.dart';

import 'service.dart';

class Pattern039View extends StatelessWidget {
  const Pattern039View({super.key, this.bundle});
  final AssetBundle? bundle;

  @override
  Widget build(BuildContext context) => ProcessedListExample(
        title: 'Pattern 039: PageIndicator',
        asset: Pattern039Service(bundle: bundle),
      );
}
