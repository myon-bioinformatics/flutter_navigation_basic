import 'dart:convert';

import 'package:flutter/services.dart';

/// UI/platform boundary for lists already processed by an external producer.
/// No predicate evaluation or synthetic fallback result belongs here.
class JsonListAsset {
  JsonListAsset(this.path, {AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final String path;
  final AssetBundle _bundle;

  Future<List<dynamic>> load() async {
    final payload = jsonDecode(await _bundle.loadString(path, cache: false));
    if (payload is! Map<String, dynamic> || payload['values'] is! List) {
      throw const FormatException('Expected a JSON object with a values list');
    }
    return List<dynamic>.unmodifiable(payload['values'] as List);
  }
}
