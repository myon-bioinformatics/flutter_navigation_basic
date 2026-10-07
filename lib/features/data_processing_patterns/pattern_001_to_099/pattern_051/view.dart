import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/data_processing/processed_list_example.dart';
import 'service.dart';
class Pattern051View extends StatelessWidget {
  const Pattern051View({super.key, this.bundle});
  final AssetBundle? bundle;
  @override Widget build(BuildContext context) => ProcessedListExample(title: 'Pattern 051: SelectableList', asset: Pattern051Service(bundle: bundle));
}
