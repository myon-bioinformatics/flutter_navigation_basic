import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/data_processing/processed_list_example.dart';
import 'service.dart';
class Pattern049View extends StatelessWidget {
  const Pattern049View({super.key, this.bundle});
  final AssetBundle? bundle;
  @override
  Widget build(BuildContext context) => ProcessedListExample(title: 'Pattern 049: GroupedList', asset: Pattern049Service(bundle: bundle));
}
