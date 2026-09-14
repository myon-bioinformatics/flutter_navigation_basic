/// Runtime helpers that map fullwidth / compatibility ASCII into plain ASCII.
///
/// Used at parse boundaries (`int` / `double` / `Uri`) and by
/// [AsciiFullwidthTextInputFormatter] so IME/clipboard fullwidth digits never
/// reach numeric parsers as U+FF0x code points.
library;

/// Maps fullwidth ASCII and related punctuation into halfwidth ASCII.
///
/// - U+FF01–U+FF5E → corresponding U+0021–U+007E (`codeUnit - 0xFEE0`)
/// - Ideographic space U+3000 → ASCII space
/// - Minus sign U+2212 → ASCII hyphen-minus `-`
///
/// All other code points are left unchanged. Mapping is 1:1 so selection
/// offsets stay stable when used from a [TextInputFormatter].
String normalizeAsciiFullwidth(String input) {
  if (input.isEmpty) return input;

  final buffer = StringBuffer();
  for (final unit in input.runes) {
    if (unit >= 0xFF01 && unit <= 0xFF5E) {
      buffer.writeCharCode(unit - 0xFEE0);
    } else if (unit == 0x3000) {
      buffer.writeCharCode(0x20);
    } else if (unit == 0x2212) {
      buffer.writeCharCode(0x2D);
    } else {
      buffer.writeCharCode(unit);
    }
  }
  return buffer.toString();
}

/// True when [input] contains any code point that [normalizeAsciiFullwidth]
/// would rewrite.
bool containsAsciiFullwidth(String input) {
  for (final unit in input.runes) {
    if ((unit >= 0xFF01 && unit <= 0xFF5E) ||
        unit == 0x3000 ||
        unit == 0x2212) {
      return true;
    }
  }
  return false;
}

/// True when [input] still contains fullwidth digits `０-９` (U+FF10–U+FF19).
bool containsFullwidthDigits(String input) {
  for (final unit in input.runes) {
    if (unit >= 0xFF10 && unit <= 0xFF19) return true;
  }
  return false;
}

int? tryParseAsciiInt(String raw, {int? radix}) =>
    int.tryParse(normalizeAsciiFullwidth(raw).trim(), radix: radix);

double? tryParseAsciiDouble(String raw) =>
    double.tryParse(normalizeAsciiFullwidth(raw).trim());

Uri? tryParseAsciiUri(String raw) {
  final normalized = normalizeAsciiFullwidth(raw).trim();
  if (normalized.isEmpty) return null;
  return Uri.tryParse(normalized);
}
