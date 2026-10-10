import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/data_processing/json_list_asset.dart';
import 'package:flutter_application_1/core/data_processing/processed_list_example.dart';

class Pattern051View extends StatelessWidget {
  const Pattern051View({super.key, this.bundle});
  final AssetBundle? bundle;

  @override
  Widget build(BuildContext context) => ProcessedListExample(
    title: 'Pattern 051: SelectableList',
    asset: JsonListAsset('assets/data_processing/command_051.json', bundle: bundle),
  );
}
