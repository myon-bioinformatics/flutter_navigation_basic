import 'package:flutter_application_1/shared/display/display_locale_codes.dart';
import 'package:flutter_application_1/shared/display/display_scope.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads and persists app-wide ISO 639-3 locale', () async {
    SharedPreferences.setMockInitialValues({
      DisplayController.preferenceKey: 'jpn',
    });
    final controller = await DisplayController.load();
    expect(controller.locale, 'jpn');

    await controller.setLocale('fra');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(DisplayController.preferenceKey), 'fra');
  });

  test('migrates legacy two-letter codes to ISO 639-3 on read', () async {
    SharedPreferences.setMockInitialValues({
      DisplayController.preferenceKey: 'ja',
    });
    final controller = await DisplayController.load();
    expect(controller.locale, 'jpn');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(DisplayController.preferenceKey), 'jpn');
  });

  test('migrates legacy Now Timeline locale when app locale is absent', () async {
    SharedPreferences.setMockInitialValues({
      DisplayController.legacyNowTimelinePreferenceKey: 'zh',
    });
    final controller = await DisplayController.load();
    expect(controller.locale, 'zho');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(DisplayController.preferenceKey), 'zho');
  });

  test('accepts id/in aliases for Indonesian', () async {
    SharedPreferences.setMockInitialValues({
      DisplayController.preferenceKey: 'id',
    });
    final controller = await DisplayController.load();
    expect(controller.locale, 'ind');
  });

  test('invalid stored locale falls back to English', () async {
    SharedPreferences.setMockInitialValues({
      DisplayController.preferenceKey: 'xx',
    });
    final controller = await DisplayController.load();
    expect(controller.locale, DisplayLocaleCodes.eng);
  });

  test('external boundary maps ISO 639-3 to BCP 47 / Flutter Locale', () {
    expect(DisplayLocaleCodes.toBcp47LanguageTag('ind'), 'id');
    expect(DisplayLocaleCodes.toBcp47LanguageTag('deu'), 'de');
    expect(DisplayLocaleCodes.toBcp47LanguageTag('swa'), 'sw');
    expect(DisplayLocaleCodes.toFlutterLocale('jpn').languageCode, 'ja');
  });
}
