import 'dart:typed_data';

/// Result of reading an image from the system clipboard (no raw preview).
enum ClipboardImageReadKind { bytes, empty, denied }

class ClipboardImageRead {
  const ClipboardImageRead._(this.kind, {this.bytes});

  const ClipboardImageRead.bytes(Uint8List bytes)
      : this._(ClipboardImageReadKind.bytes, bytes: bytes);

  const ClipboardImageRead.empty() : this._(ClipboardImageReadKind.empty);

  const ClipboardImageRead.denied() : this._(ClipboardImageReadKind.denied);

  final ClipboardImageReadKind kind;
  final Uint8List? bytes;
}
