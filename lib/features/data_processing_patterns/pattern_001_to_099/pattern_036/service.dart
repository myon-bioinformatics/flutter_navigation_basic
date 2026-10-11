// Pattern 036: LazyList — Python collection-window state boundary.
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/data_processing/json_list_asset.dart';

class Pattern036Service extends JsonListAsset {
  Pattern036Service({AssetBundle? bundle})
      : super('assets/data_processing/window_036.json', bundle: bundle);
}
