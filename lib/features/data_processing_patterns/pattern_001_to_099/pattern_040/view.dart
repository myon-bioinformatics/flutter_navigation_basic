// Pattern 040: PageSize — rendered Python state, no GetX controller.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/data_processing/processed_list_example.dart';

import 'service.dart';

class Pattern040View extends StatelessWidget {
  const Pattern040View({super.key, this.bundle});
  final AssetBundle? bundle;

  @override
  Widget build(BuildContext context) => ProcessedListExample(
        title: 'Pattern 040: PageSize',
        asset: Pattern040Service(bundle: bundle),
      );
}
