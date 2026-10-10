// Pattern 041: OffsetLimit — rendered Python state, no GetX controller.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/data_processing/processed_list_example.dart';

import 'service.dart';

class Pattern041View extends StatelessWidget {
  const Pattern041View({super.key, this.bundle});
  final AssetBundle? bundle;

  @override
  Widget build(BuildContext context) => ProcessedListExample(
        title: 'Pattern 041: OffsetLimit',
        asset: Pattern041Service(bundle: bundle),
      );
}
