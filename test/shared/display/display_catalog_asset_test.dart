import 'dart:convert';
import 'dart:io';

import 'package:flutter_application_1/shared/display/display_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all declared display locales contain the same Now Timeline keys', () {
    final decoded = jsonDecode(
      File('assets/display/app_text.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final locales = (decoded['locales'] as Map).cast<String, dynamic>();

    expect(locales.keys.toSet(), DisplayCatalog.supportedLocales.toSet());

    final english = (locales['en'] as Map).keys.map((key) => key.toString()).toSet();
    expect(english, isNotEmpty);
    for (final locale in DisplayCatalog.supportedLocales) {
      final values = (locales[locale] as Map).cast<String, dynamic>();
      final keys = values.keys.toSet();
      expect(keys, english, reason: 'display keys differ for $locale');
      for (final entry in values.entries) {
        expect(
          entry.value.toString().trim(),
          isNotEmpty,
          reason: 'empty translation for $locale / ${entry.key}',
        );
      }
    }
  });

  test('UN-language locale entries are present for Now Timeline', () {
    expect(
      DisplayCatalog.supportedLocales,
      containsAll(const ['en', 'fr', 'es', 'ar', 'zh', 'ru']),
    );
  });

  test('Japanese and Portuguese locale entries remain complete', () {
    final decoded = jsonDecode(
      File('assets/display/app_text.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final locales = (decoded['locales'] as Map).cast<String, dynamic>();
    final englishCount = (locales['en'] as Map).length;

    for (final locale in const ['ja', 'pt']) {
      expect((locales[locale] as Map).length, englishCount);
    }
  });
}
