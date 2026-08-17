import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'display_catalog.dart';

class DisplayController extends ChangeNotifier {
  DisplayController._(this.catalog, this._preferences, this._locale);

  static const preferenceKey = 'app.display.locale.v1';
  static const legacyNowTimelinePreferenceKey = 'now_timeline.locale.v1';

  final DisplayCatalog catalog;
  final SharedPreferences _preferences;
  String _locale;

  String get locale => _locale;

  static Future<DisplayController> load() async {
    final catalog = await DisplayCatalog.load();
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(preferenceKey);
    final legacy = preferences.getString(legacyNowTimelinePreferenceKey);
    final candidate = saved ?? legacy ?? 'en';
    final locale = catalog.supports(candidate) ? candidate : 'en';

    if (saved == null && catalog.supports(candidate)) {
      await preferences.setString(preferenceKey, locale);
    }

    return DisplayController._(catalog, preferences, locale);
  }

  String text(
    String key, {
    Map<String, Object?> arguments = const {},
  }) =>
      catalog.text(_locale, key, arguments: arguments);

  Future<void> setLocale(String value) async {
    final resolved = catalog.supports(value) ? value : 'en';
    if (resolved == _locale) return;
    _locale = resolved;
    notifyListeners();
    await _preferences.setString(preferenceKey, resolved);
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

  static DisplayController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DisplayScope>()?.notifier;
}

class DisplayLocalePicker extends StatelessWidget {
  const DisplayLocalePicker({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: display.locale,
        isDense: compact,
        padding: const EdgeInsets.symmetric(horizontal: 8),
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
