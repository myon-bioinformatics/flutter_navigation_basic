import 'dart:typed_data';

/// Result of reading an image from the system clipboard (no raw preview).
enum ClipboardImageReadKind {
  bytes,
  empty,
  denied,
  unavailable,
  tooLarge,
  readFailed,
}

class ClipboardImageRead {
  const ClipboardImageRead._(this.kind, {this.bytes});

  const ClipboardImageRead.bytes(Uint8List bytes)
      : this._(ClipboardImageReadKind.bytes, bytes: bytes);

  const ClipboardImageRead.empty() : this._(ClipboardImageReadKind.empty);

  const ClipboardImageRead.denied() : this._(ClipboardImageReadKind.denied);

  const ClipboardImageRead.unavailable()
      : this._(ClipboardImageReadKind.unavailable);

  const ClipboardImageRead.tooLarge() : this._(ClipboardImageReadKind.tooLarge);

  const ClipboardImageRead.readFailed()
      : this._(ClipboardImageReadKind.readFailed);

  final ClipboardImageReadKind kind;
  final Uint8List? bytes;
}
