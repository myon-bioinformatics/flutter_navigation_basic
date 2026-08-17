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

    expect(locales.keys.toSet(), containsAll(DisplayCatalog.supportedLocales));

    final english = (locales['en'] as Map).keys.map((key) => key.toString()).toSet();
    expect(english, isNotEmpty);
    for (final locale in DisplayCatalog.supportedLocales) {
      final keys = (locales[locale] as Map).keys.map((key) => key.toString()).toSet();
      expect(keys, english, reason: 'display keys differ for $locale');
    }
  });

  test('French, Spanish and Portuguese have full Now Timeline entries', () {
    final decoded = jsonDecode(
      File('assets/display/app_text.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final locales = (decoded['locales'] as Map).cast<String, dynamic>();
    final englishCount = (locales['en'] as Map).length;

    for (final locale in const ['fr', 'es', 'pt']) {
      expect((locales[locale] as Map).length, englishCount);
    }
  });
}
