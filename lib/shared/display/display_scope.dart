import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'display_catalog.dart';

class DisplayController extends ChangeNotifier {
  DisplayController._(this.catalog, this._locale);

  static const _localeKey = 'app.display.locale.v1';

  final DisplayCatalog catalog;
  String _locale;

  String get locale => _locale;

  static Future<DisplayController> load() async {
    final catalog = await DisplayCatalog.load();
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_localeKey) ?? 'en';
    final locale = catalog.supports(stored) ? stored : 'en';
    return DisplayController._(catalog, locale);
  }

  String text(String key) => catalog.text(_locale, key);

  Future<void> setLocale(String value) async {
    if (!catalog.supports(value) || value == _locale) return;
    _locale = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, value);
  }
}

class DisplayScope extends InheritedNotifier<DisplayController> {
  const DisplayScope({
    super.key,
    required DisplayController controller,
    required super.child,
  }) : super(notifier: controller);

  static DisplayController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<DisplayScope>();
    if (scope == null || scope.notifier == null) {
      throw StateError('DisplayScope is not available in this context.');
    }
    return scope.notifier!;
  }
}

class DisplayLocalePicker extends StatelessWidget {
  const DisplayLocalePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: display.locale,
        items: DisplayCatalog.supportedLocales
            .map(
              (locale) => DropdownMenuItem(
                value: locale,
                child: Text(locale.toUpperCase()),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) display.setLocale(value);
        },
      ),
    );
  }
}
