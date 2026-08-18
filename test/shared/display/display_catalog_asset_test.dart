import 'dart:convert';
import 'dart:io';

import 'package:flutter_application_1/shared/display/display_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> loadLocales() {
    final decoded = jsonDecode(
      File('assets/display/app_text.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    return (decoded['locales'] as Map).cast<String, dynamic>();
  }

  test('all supported locales contain the same non-empty display key set', () {
    final locales = loadLocales();
    expect(locales.keys.toSet(), DisplayCatalog.supportedLocales.toSet());

    final english = (locales['en'] as Map).keys.map((key) => key.toString()).toSet();
    expect(english, isNotEmpty);

    for (final locale in DisplayCatalog.supportedLocales) {
      final values = (locales[locale] as Map).cast<String, dynamic>();
      final keys = values.keys.toSet();
      expect(
        keys,
        english,
        reason: 'display keys differ for $locale; '
            'missing=${english.difference(keys).toList()..sort()} '
            'extra=${keys.difference(english).toList()..sort()}',
      );
      for (final key in english) {
        expect(
          values[key],
          isA<String>().having((value) => value.trim(), 'trimmed value', isNotEmpty),
          reason: 'blank display value for $locale:$key',
        );
      }
    }
  });

  test('required app-wide namespaces are represented', () {
    final locales = loadLocales();
    final english = (locales['en'] as Map).cast<String, dynamic>();
    for (final prefix in DisplayCatalog.requiredNamespaces) {
      expect(
        english.keys.any((key) => key.startsWith(prefix)),
        isTrue,
        reason: 'missing display namespace $prefix',
      );
    }
  });

  test('UN-language locales plus Japanese and Portuguese remain available', () {
    expect(
      DisplayCatalog.supportedLocales,
      containsAll(const ['en', 'ja', 'fr', 'es', 'pt', 'ar', 'zh', 'ru']),
    );
  });
}
