import 'package:flutter/services.dart';

import '../../core/utils/ascii_fullwidth.dart';

/// Converts fullwidth ASCII (and U+2212 / U+3000) to halfwidth as the user
/// types or pastes.
///
/// While an IME composition range is active (`composing` valid and not
/// collapsed), this formatter returns [newValue] unchanged so the composing
/// text stays under IME control. Normalization runs after composition
/// commits (and immediately on paste, which is usually collapsed).
class AsciiFullwidthTextInputFormatter extends TextInputFormatter {
  const AsciiFullwidthTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final composing = newValue.composing;
    if (composing.isValid && !composing.isCollapsed) {
      return newValue;
    }

    final text = newValue.text;
    if (!containsAsciiFullwidth(text)) return newValue;

    final normalized = normalizeAsciiFullwidth(text);
    if (normalized == text) return newValue;

    // 1:1 rune mapping ⇒ UTF-16 offsets for BMP fullwidth chars stay equal.
    return TextEditingValue(
      text: normalized,
      selection: newValue.selection,
      composing: newValue.composing,
    );
  }
}

/// Shared formatter list for numeric / URL fields that must stay ASCII.
const List<TextInputFormatter> asciiFullwidthInputFormatters =
    <TextInputFormatter>[
  AsciiFullwidthTextInputFormatter(),
];
