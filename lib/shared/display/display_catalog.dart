import 'dart:convert';

import 'package:flutter/services.dart';

class DisplayCatalog {
  DisplayCatalog._(this._values);

  final Map<String, Map<String, String>> _values;

  static const supportedLocales = <String>[
    'en',
    'ja',
    'fr',
    'es',
    'pt',
    'ar',
    'zh',
    'ru',
  ];

  static Future<DisplayCatalog> load() async {
    final raw = await rootBundle.loadString('assets/display/app_text.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final locales = decoded['locales'] as Map<String, dynamic>;
    final values = <String, Map<String, String>>{};
    for (final locale in supportedLocales) {
      final source = (locales[locale] as Map<dynamic, dynamic>?) ?? const {};
      values[locale] = source.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    }
    return DisplayCatalog._(values);
  }

  String text(String locale, String key) =>
      _values[locale]?[key] ?? _values['en']?[key] ?? key;

  bool supports(String locale) => supportedLocales.contains(locale);
}
