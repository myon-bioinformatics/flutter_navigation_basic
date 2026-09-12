import 'package:flutter/material.dart';

/// ISO 639-3 display-locale identifiers used inside the app.
///
/// External boundaries (Flutter [Locale], HTML `lang`, BCP 47 tags) must go
/// through [toBcp47LanguageTag] / [toFlutterLocale] instead of using these
/// codes directly.
class DisplayLocaleCodes {
  DisplayLocaleCodes._();

  static const eng = 'eng';
  static const jpn = 'jpn';
  static const fra = 'fra';
  static const spa = 'spa';
  static const por = 'por';
  static const ara = 'ara';
  static const zho = 'zho';
  static const rus = 'rus';
  static const ind = 'ind';
  static const deu = 'deu';
  static const swa = 'swa';

  static const supported = <String>[
    eng,
    jpn,
    fra,
    spa,
    por,
    ara,
    zho,
    rus,
    ind,
    deu,
    swa,
  ];

  /// Legacy two-letter (and informal) codes persisted before ISO 639-3.
  static const legacyToIso6393 = <String, String>{
    'en': eng,
    'ja': jpn,
    'fr': fra,
    'es': spa,
    'pt': por,
    'ar': ara,
    'zh': zho,
    'ru': rus,
    'id': ind,
    'in': ind,
    'de': deu,
    'sw': swa,
  };

  /// BCP 47 / HTML `lang` / Flutter language codes for external APIs.
  static const iso6393ToBcp47 = <String, String>{
    eng: 'en',
    jpn: 'ja',
    fra: 'fr',
    spa: 'es',
    por: 'pt',
    ara: 'ar',
    zho: 'zh',
    rus: 'ru',
    ind: 'id',
    deu: 'de',
    swa: 'sw',
  };

  /// Whether [raw] is a supported ISO 639-3 code or a known legacy alias.
  static bool isKnown(String? raw) {
    if (raw == null || raw.trim().isEmpty) return false;
    final trimmed = raw.trim().toLowerCase();
    return supported.contains(trimmed) || legacyToIso6393.containsKey(trimmed);
  }

  /// Resolves a stored or UI-selected code to a supported ISO 639-3 locale.
  ///
  /// Unknown values fall back to [eng].
  static String canonicalize(String? raw, {String fallback = eng}) {
    if (raw == null || raw.trim().isEmpty) return fallback;
    final trimmed = raw.trim().toLowerCase();
    if (supported.contains(trimmed)) return trimmed;
    final migrated = legacyToIso6393[trimmed];
    if (migrated != null) return migrated;
    return fallback;
  }

  static String toBcp47LanguageTag(String iso6393) =>
      iso6393ToBcp47[canonicalize(iso6393)] ?? 'en';

  static Locale toFlutterLocale(String iso6393) =>
      Locale(toBcp47LanguageTag(iso6393));
}
