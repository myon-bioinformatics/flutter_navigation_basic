/// Digest Authentication `nc` (nonce-count) helpers.
///
/// RFC 7616 requires `nc` to be exactly 8 hexadecimal digits. Decimal
/// [int.tryParse] is incorrect: valid values such as `0000000a` must parse
/// as 10, and non-hex or wrong-length strings must be rejected.
abstract final class DigestNc {
  static final RegExp _exact8Hex = RegExp(r'^[0-9a-fA-F]{8}$');

  /// Parses an 8-digit hex nonce-count. Returns null when malformed.
  static int? tryParse(String nc) {
    if (!_exact8Hex.hasMatch(nc)) return null;
    return int.parse(nc, radix: 16);
  }

  /// Formats a positive nonce-count as exactly 8 lowercase hex digits.
  static String format(int value) {
    if (value < 1 || value > 0xffffffff) {
      throw ArgumentError.value(value, 'value', 'Digest nc out of range');
    }
    return value.toRadixString(16).padLeft(8, '0');
  }
}
