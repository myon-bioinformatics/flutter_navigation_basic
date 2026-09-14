import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

bool _isPng(Uint8List bytes) {
  const sig = <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
  if (bytes.length < sig.length) return false;
  for (var i = 0; i < sig.length; i++) {
    if (bytes[i] != sig[i]) return false;
  }
  return true;
}

(int, int) _pngSize(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  return (data.getUint32(16), data.getUint32(20));
}

bool _isJpeg(Uint8List bytes) =>
    bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;

(int, int)? _jpegSize(Uint8List bytes) {
  var i = 2;
  while (i + 9 < bytes.length) {
    if (bytes[i] != 0xFF) return null;
    final marker = bytes[i + 1];
    final len = (bytes[i + 2] << 8) | bytes[i + 3];
    if (marker == 0xC0 || marker == 0xC2) {
      final h = (bytes[i + 5] << 8) | bytes[i + 6];
      final w = (bytes[i + 7] << 8) | bytes[i + 8];
      return (w, h);
    }
    i += 2 + len;
  }
  return null;
}

Uint8List _loadFixture(String name) =>
    File('test/fixtures/photo_studio/$name').readAsBytesSync();

void main() {
  test('vertical markers PNG fixture matches portrait geometry size', () {
    final bytes = _loadFixture('test_1_vertical_markers.png');
    expect(_isPng(bytes), isTrue);
    final (w, h) = _pngSize(bytes);
    expect(w, 1080);
    expect(h, 1920);
  });

  test('horizontal color-lines JPEG fixture matches landscape size', () {
    final bytes = _loadFixture('test_2_horizontal_color_lines.jpg');
    expect(_isJpeg(bytes), isTrue);
    final size = _jpegSize(bytes);
    expect(size, isNotNull);
    expect(size!.$1, 1920);
    expect(size.$2, 1080);
  });

  test('transparent shapes PNG fixture is square RGBA asset', () {
    final bytes = _loadFixture('test_3_transparent_shapes.png');
    expect(_isPng(bytes), isTrue);
    final (w, h) = _pngSize(bytes);
    expect(w, 1024);
    expect(h, 1024);
    expect(bytes[25], 6);
  });
}
