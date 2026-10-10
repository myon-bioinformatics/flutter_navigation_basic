// Pattern 038: Prefetch — Python collection-window state boundary.
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/data_processing/json_list_asset.dart';

class Pattern038Service extends JsonListAsset {
  Pattern038Service({AssetBundle? bundle})
      : super('assets/data_processing/window_038.json', bundle: bundle);
}
