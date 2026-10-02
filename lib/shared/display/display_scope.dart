import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'display_catalog.dart';
import 'display_locale_codes.dart';

class DisplayController extends ChangeNotifier {
  DisplayController._(this.catalog, this._preferences, this._locale);

  static const preferenceKey = 'app.display.locale.v1';
  static const legacyNowTimelinePreferenceKey = 'now_timeline.locale.v1';

  final DisplayCatalog catalog;
  final SharedPreferences? _preferences;
  String _locale;

  /// Canonical ISO 639-3 locale code (e.g. `eng`, `jpn`).
  String get locale => _locale;

  /// BCP 47 language tag for Flutter / HTML / external APIs.
  String get bcp47LanguageTag => DisplayLocaleCodes.toBcp47LanguageTag(_locale);

  Locale get flutterLocale => DisplayLocaleCodes.toFlutterLocale(_locale);

  /// Catalog failure propagates (no catalog means no UI text). A preferences
  /// or storage failure is non-fatal: the session runs with the default
  /// locale and nothing is persisted.
  static Future<DisplayController> load({
    Future<DisplayCatalog> Function() catalogLoader = DisplayCatalog.load,
    Future<SharedPreferences> Function() preferencesLoader =
        SharedPreferences.getInstance,
  }) async {
    final catalog = await catalogLoader();
    final SharedPreferences preferences;
    try {
      preferences = await preferencesLoader();
    } catch (_) {
      return DisplayController._(catalog, null, DisplayLocaleCodes.eng);
    }
    final saved = preferences.getString(preferenceKey);
    final legacy = preferences.getString(legacyNowTimelinePreferenceKey);
    final locale = DisplayLocaleCodes.canonicalize(saved ?? legacy);

    if (saved != locale) {
      await _persist(preferences, locale);
    }

    return DisplayController._(catalog, preferences, locale);
  }

  static Future<void> _persist(SharedPreferences? prefs, String locale) async {
    if (prefs == null) return;
    try {
      await prefs.setString(preferenceKey, locale);
    } catch (_) {
      // Best-effort; the in-memory locale stays authoritative.
    }
  }

  String text(
    String key, {
    Map<String, Object?> arguments = const {},
  }) =>
      catalog.text(_locale, key, arguments: arguments);

  Future<void> setLocale(String value) async {
    final resolved = DisplayLocaleCodes.canonicalize(value);
    if (_locale == resolved) {
      // Still rewrite prefs when a legacy two-letter code was passed in.
      await _persist(_preferences, resolved);
      return;
    }
    _locale = resolved;
    notifyListeners();
    await _persist(_preferences, resolved);
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
    if (scope?.notifier == null) {
      throw StateError('DisplayScope is not available in this context.');
    }
    return scope!.notifier!;
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
