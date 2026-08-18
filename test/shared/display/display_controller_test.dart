import 'package:flutter_application_1/shared/display/display_scope.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads and persists app-wide locale', () async {
    SharedPreferences.setMockInitialValues({
      DisplayController.preferenceKey: 'ja',
    });
    final controller = await DisplayController.load();
    expect(controller.locale, 'ja');

    await controller.setLocale('fr');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(DisplayController.preferenceKey), 'fr');
  });

  test('migrates legacy Now Timeline locale when app locale is absent', () async {
    SharedPreferences.setMockInitialValues({
      DisplayController.legacyNowTimelinePreferenceKey: 'zh',
    });
    final controller = await DisplayController.load();
    expect(controller.locale, 'zh');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(DisplayController.preferenceKey), 'zh');
  });

  test('invalid stored locale falls back to English', () async {
    SharedPreferences.setMockInitialValues({
      DisplayController.preferenceKey: 'xx',
    });
    final controller = await DisplayController.load();
    expect(controller.locale, 'en');
  });
}
