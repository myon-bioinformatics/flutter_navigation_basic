import 'dart:convert';
import 'dart:io';

import 'src/toolkit_io.dart';

Future<void> main(List<String> args) async {
  final asJson = args.contains('--json');
  final root = Directory.current;

  final libFiles = await dartFilesUnder(Directory('lib'));
  final testFiles = await dartFilesUnder(Directory('test'));
  final toolFiles = await dartFilesUnder(Directory('tool'));
  final allDartFiles = [...libFiles, ...testFiles, ...toolFiles];

  final getxImportFiles =
      await countFilesContaining(libFiles, 'package:get/get.dart');
  final getViewCount = await countTextOccurrences(libFiles, 'GetView<');
  final getxControllerCount =
      await countTextOccurrences(libFiles, 'GetxController');
  final obxCount = await countTextOccurrences(libFiles, 'Obx(');
  final obsCount = await countTextOccurrences(libFiles, '.obs');

  final patternDirectories = <Directory>[];
  final features = Directory('lib/features');
  final terminalPattern = RegExp(r'^pattern_\d{3}$');
  if (await features.exists()) {
    await for (final entity in features.list(recursive: true, followLinks: false)) {
      if (entity is! Directory) continue;
      final segments = entity.uri.pathSegments.where((segment) => segment.isNotEmpty);
      if (segments.isEmpty) continue;
      if (terminalPattern.hasMatch(segments.last)) patternDirectories.add(entity);
    }
  }

  final repoSourceBytes = await directorySize(
    root,
    excludedTopLevel: {'.git', '.dart_tool', 'build'},
  );
  final assetBytes = await directorySize(Directory('assets'));
  final currentWebBuildBytes = await directorySize(Directory('build/web'));

  final flutterVersion = await runCommand('flutter', ['--version', '--machine']);
  Map<String, dynamic>? flutter;
  if (flutterVersion.ok) {
    try {
      flutter = jsonDecode(flutterVersion.stdoutText) as Map<String, dynamic>;
    } on FormatException {
      flutter = null;
    }
  }

  final gitHead = await runCommand('git', ['rev-parse', '--short', 'HEAD']);
  final directVersions = await _readDirectLockVersions(File('pubspec.lock'));

  final report = <String, dynamic>{
    'sdk': {
      'flutter': flutter == null
          ? flutterVersion.stdoutText.trim()
          : flutter['frameworkVersion'],
      'flutterChannel': flutter?['channel'],
      'dart': flutter?['dartSdkVersion'] ?? Platform.version.split(' ').first,
    },
    'git': {'head': gitHead.stdoutText.trim()},
    'repository': {
      'sourceBytesExcludingBuildGitToolState': repoSourceBytes,
      'sourceSize': formatBytes(repoSourceBytes),
      'dartFiles': allDartFiles.length,
      'libDartFiles': libFiles.length,
      'testDartFiles': testFiles.length,
      'toolDartFiles': toolFiles.length,
      'patternDirectories': patternDirectories.length,
      'assetBytes': assetBytes,
      'assetSize': formatBytes(assetBytes),
    },
    'getx': {
      'importFilesInLib': getxImportFiles,
      'GetViewOccurrences': getViewCount,
      'GetxControllerOccurrences': getxControllerCount,
      'ObxOccurrences': obxCount,
      'obsOccurrences': obsCount,
      'note': 'Reference/generated catalogue usage is counted intentionally.',
    },
    'dependencies': directVersions,
    'build': {
      'webBytesIfPresent': currentWebBuildBytes,
      'webSizeIfPresent': formatBytes(currentWebBuildBytes),
    },
  };

  if (asJson) {
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(report));
    return;
  }

  stdout.writeln('=== Developer Toolkit Inspector ===');
  stdout.writeln('Flutter : ${report['sdk']['flutter']} (${report['sdk']['flutterChannel']})');
  stdout.writeln('Dart    : ${report['sdk']['dart']}');
  stdout.writeln('Git HEAD: ${report['git']['head']}');
  stdout.writeln();
  stdout.writeln('Repository');
  stdout.writeln('  source size : ${report['repository']['sourceSize']}');
  stdout.writeln('  Dart files  : ${report['repository']['dartFiles']} '
      '(lib ${report['repository']['libDartFiles']}, '
      'test ${report['repository']['testDartFiles']}, '
      'tool ${report['repository']['toolDartFiles']})');
  stdout.writeln('  patterns    : ${report['repository']['patternDirectories']}');
  stdout.writeln('  assets      : ${report['repository']['assetSize']}');
  stdout.writeln();
  stdout.writeln('GetX residuals (lib/, reference catalogue included)');
  stdout.writeln('  import files     : ${report['getx']['importFilesInLib']}');
  stdout.writeln('  GetView          : ${report['getx']['GetViewOccurrences']}');
  stdout.writeln('  GetxController   : ${report['getx']['GetxControllerOccurrences']}');
  stdout.writeln('  Obx              : ${report['getx']['ObxOccurrences']}');
  stdout.writeln('  .obs             : ${report['getx']['obsOccurrences']}');
  stdout.writeln();
  stdout.writeln('Direct locked dependencies');
  for (final entry in directVersions.entries) {
    stdout.writeln('  ${entry.key}: ${entry.value}');
  }
  stdout.writeln();
  stdout.writeln('Existing build/web: ${report['build']['webSizeIfPresent']}');
}

Future<Map<String, String>> _readDirectLockVersions(File file) async {
  if (!await file.exists()) return const {};
  final lines = await file.readAsLines();
  final versions = <String, String>{};
  String? package;
  var direct = false;

  for (final line in lines) {
    final packageMatch = RegExp(r'^  ([A-Za-z0-9_]+):$').firstMatch(line);
    if (packageMatch != null) {
      package = packageMatch.group(1);
      direct = false;
      continue;
    }
    if (package == null) continue;
    if (line.contains('dependency: "direct main"') ||
        line.contains('dependency: "direct dev"')) {
      direct = true;
      continue;
    }
    if (direct) {
      final versionMatch = RegExp(r'^    version: "?([^" ]+)"?$').firstMatch(line);
      if (versionMatch != null) {
        versions[package] = versionMatch.group(1)!;
        direct = false;
      }
    }
  }
  return versions;
}
