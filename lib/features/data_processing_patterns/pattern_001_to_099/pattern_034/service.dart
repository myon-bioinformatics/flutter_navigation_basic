// Pattern 034: LoadMore — Python collection-window state boundary.
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/data_processing/json_list_asset.dart';

class Pattern034Service extends JsonListAsset {
  Pattern034Service({AssetBundle? bundle})
      : super('assets/data_processing/window_034.json', bundle: bundle);
}
