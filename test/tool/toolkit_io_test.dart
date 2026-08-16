import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/toolkit_io.dart';

void main() {
  group('directorySize', () {
    late Directory root;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('toolkit_io_test_');
      await File('${root.path}/root.txt').writeAsBytes(List<int>.filled(3, 1));
      await Directory('${root.path}/keep').create();
      await File('${root.path}/keep/kept.bin').writeAsBytes(List<int>.filled(5, 1));
      await Directory('${root.path}/skip/nested').create(recursive: true);
      await File('${root.path}/skip/nested/ignored.bin')
          .writeAsBytes(List<int>.filled(11, 1));
    });

    tearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    test('counts all files when no exclusions are supplied', () async {
      expect(await directorySize(root), 19);
    });

    test('prunes excluded top-level directories', () async {
      expect(await directorySize(root, excludedTopLevel: {'skip'}), 8);
    });
  });

  test('formatBytes uses binary units', () {
    expect(formatBytes(1024), '1.00 KiB');
    expect(formatBytes(1024 * 1024), '1.00 MiB');
  });
}
