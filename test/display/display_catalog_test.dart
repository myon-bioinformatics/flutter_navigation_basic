import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/shared/display/display_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all supported locales resolve the same display key set', () async {
    final catalog = await DisplayCatalog.load();
    final english = catalog.keys('en');

    expect(english, isNotEmpty);
    for (final locale in DisplayCatalog.supportedLocales) {
      expect(catalog.keys(locale), english, reason: 'key set differs for $locale');
    }
  });

  test('unknown locale/key safely falls back', () async {
    final catalog = await DisplayCatalog.load();
    expect(catalog.text('xx', 'home.title'), catalog.text('en', 'home.title'));
    expect(catalog.text('en', 'missing.key'), 'missing.key');
  });

  test('display interpolation replaces named arguments', () async {
    final catalog = await DisplayCatalog.load();
    final value = catalog.text(
      'en',
      'nowTimeline.title',
      arguments: const {'unused': 1},
    );
    expect(value, 'Now Timeline');
  });
}
