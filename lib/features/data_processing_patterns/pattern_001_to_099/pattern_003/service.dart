// Pattern 003: FilterNested — only the Python result-asset boundary.
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/data_processing/json_list_asset.dart';

class Pattern003Service extends JsonListAsset {
  Pattern003Service({AssetBundle? bundle})
      : super('assets/data_processing/filter_nested.json', bundle: bundle);
}
