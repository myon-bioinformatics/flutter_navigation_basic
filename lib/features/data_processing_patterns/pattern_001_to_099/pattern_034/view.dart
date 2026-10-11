// Pattern 034: LoadMore — rendered Python state, no GetX controller.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/data_processing/processed_list_example.dart';

import 'service.dart';

class Pattern034View extends StatelessWidget {
  const Pattern034View({super.key, this.bundle});
  final AssetBundle? bundle;

  @override
  Widget build(BuildContext context) => ProcessedListExample(
        title: 'Pattern 034: LoadMore',
        asset: Pattern034Service(bundle: bundle),
      );
}
