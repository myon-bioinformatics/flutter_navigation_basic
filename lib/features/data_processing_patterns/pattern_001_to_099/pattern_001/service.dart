// Pattern 001: FilterBasic — display the Python-produced catalogue example.
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/data_processing/json_list_asset.dart';

import 'model.dart';

class Pattern001Service {
  Pattern001Service({AssetBundle? bundle})
      : _asset = JsonListAsset(
          'assets/data_processing/filter_basic.json',
          bundle: bundle,
        );

  final JsonListAsset _asset;

  Future<Pattern001Result> run() async {
    final values = await _asset.load();
    return Pattern001Result(message: 'FilterBasic: $values');
  }
}
