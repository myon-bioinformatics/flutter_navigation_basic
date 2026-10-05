// Pattern 001: FilterBasic — only the Python result-asset boundary.
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/data_processing/json_list_asset.dart';

class Pattern001Service extends JsonListAsset {
  Pattern001Service({AssetBundle? bundle})
      : super('assets/data_processing/filter_basic.json', bundle: bundle);
}
