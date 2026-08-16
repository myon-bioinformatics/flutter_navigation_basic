import 'dart:io';

import 'src/toolkit_io.dart';

Future<void> main(List<String> args) async {
  final target = _valueAfter(args, '--target') ?? 'lib/main_prod.dart';
  final diagnosticsDir = Directory(
    _valueAfter(args, '--output-dir') ?? 'build/diagnostics/android-arm64',
  );
  final workspace = Directory('build/android-size-workspace');

  if (await diagnosticsDir.exists()) {
    await diagnosticsDir.delete(recursive: true);
  }
  await diagnosticsDir.create(recursive: true);

  stdout.writeln('=== Android arm64 release size analysis ===');
  stdout.writeln('target: $target');

  final hasAndroidPlatform = await Directory('android').exists();
  final workingDirectory = hasAndroidPlatform ? Directory.current : workspace;

  if (!hasAndroidPlatform) {
    stdout.writeln(
      'android/ is not tracked in this repository; creating an ephemeral '
      'measurement workspace under build/.',
    );
    if (await workspace.exists()) {
      await workspace.delete(recursive: true);
    }
    await workspace.create(recursive: true);
    await _copyMeasurementInputs(workspace);

    final scaffold = await runCommand(
      'flutter',
      ['create', '--platforms=android', '--no-pub', '.'],
      workingDirectory: workspace.path,
      stream: true,
    );
    if (!scaffold.ok) {
      exitCode = scaffold.exitCode;
      return;
    }
  }

  final startedAt = DateTime.now();
  final build = await runCommand(
    'flutter',
    [
      'build',
      'apk',
      '--release',
      '--target-platform=android-arm64',
      '--analyze-size',
      '-t',
      target,
    ],
    workingDirectory: workingDirectory.path,
    stream: true,
  );
  if (!build.ok) {
    exitCode = build.exitCode;
    return;
  }

  final apk = File(
    '${workingDirectory.path}${Platform.pathSeparator}build${Platform.pathSeparator}'
    'app${Platform.pathSeparator}outputs${Platform.pathSeparator}flutter-apk'
    '${Platform.pathSeparator}app-release.apk',
  );
  if (!await apk.exists()) {
    stderr.writeln('Android release APK was not found at ${apk.path}.');
    exitCode = 2;
    return;
  }

  final analysis = await _latestAnalysisFile(
    Directory('${workingDirectory.path}${Platform.pathSeparator}build'),
    startedAt,
  );
  if (analysis == null) {
    stderr.writeln('Flutter code-size analysis JSON was not found under the measurement build/.');
    exitCode = 2;
    return;
  }

  final copiedAnalysis = File(
    '${diagnosticsDir.path}${Platform.pathSeparator}${analysis.uri.pathSegments.last}',
  );
  await analysis.copy(copiedAnalysis.path);

  final metadata = File(
    '${diagnosticsDir.path}${Platform.pathSeparator}build_meta.json',
  );
  final meta = await runCommand(
    'dart',
    [
      'run',
      'tool/build_meta.dart',
      '--output',
      metadata.path,
      '--artifact',
      apk.path,
      '--analysis',
      copiedAnalysis.path,
      '--platform',
      'android-arm64',
      '--mode',
      'release',
    ],
    stream: true,
  );
  if (!meta.ok) {
    exitCode = meta.exitCode;
    return;
  }

  final summary = File(
    '${diagnosticsDir.path}${Platform.pathSeparator}summary.txt',
  );
  final apkBytes = await apk.length();
  final analysisBytes = await copiedAnalysis.length();
  await summary.writeAsString(
    'platform=android-arm64\n'
    'mode=release\n'
    'target=$target\n'
    'measurementWorkspace=${workingDirectory.path}\n'
    'ephemeralAndroidScaffold=${!hasAndroidPlatform}\n'
    'artifact=${apk.path}\n'
    'artifactBytes=$apkBytes\n'
    'artifactSize=${formatBytes(apkBytes)}\n'
    'analysis=${copiedAnalysis.path}\n'
    'analysisBytes=$analysisBytes\n'
    'analysisSize=${formatBytes(analysisBytes)}\n',
  );

  stdout.writeln();
  stdout.writeln('APK      : ${apk.path} (${formatBytes(apkBytes)})');
  stdout.writeln('Analysis : ${copiedAnalysis.path} (${formatBytes(analysisBytes)})');
  stdout.writeln('Metadata : ${metadata.path}');
}

Future<void> _copyMeasurementInputs(Directory workspace) async {
  for (final fileName in ['pubspec.yaml', 'pubspec.lock', 'analysis_options.yaml']) {
    final source = File(fileName);
    if (await source.exists()) {
      await source.copy(
        '${workspace.path}${Platform.pathSeparator}$fileName',
      );
    }
  }

  for (final directoryName in ['lib', 'assets']) {
    final source = Directory(directoryName);
    if (await source.exists()) {
      await _copyDirectory(
        source,
        Directory('${workspace.path}${Platform.pathSeparator}$directoryName'),
      );
    }
  }
}

Future<void> _copyDirectory(Directory source, Directory destination) async {
  await destination.create(recursive: true);
  await for (final entity in source.list(followLinks: false)) {
    final name = entity.uri.pathSegments.where((segment) => segment.isNotEmpty).last;
    final destinationPath = '${destination.path}${Platform.pathSeparator}$name';
    if (entity is Directory) {
      await _copyDirectory(entity, Directory(destinationPath));
    } else if (entity is File) {
      await entity.copy(destinationPath);
    }
  }
}

Future<File?> _latestAnalysisFile(
  Directory buildDirectory,
  DateTime startedAt,
) async {
  if (!await buildDirectory.exists()) return null;

  final candidates = <File>[];
  await for (final entity in buildDirectory.list(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is! File) continue;
    final name = entity.uri.pathSegments.last;
    if (!name.contains('-code-size-analysis_') || !name.endsWith('.json')) {
      continue;
    }
    final modified = await entity.lastModified();
    if (!modified.isBefore(startedAt.subtract(const Duration(seconds: 2)))) {
      candidates.add(entity);
    }
  }
  if (candidates.isEmpty) return null;
  candidates.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
  return candidates.first;
}

String? _valueAfter(List<String> args, String flag) {
  final index = args.indexOf(flag);
  if (index < 0 || index + 1 >= args.length) return null;
  final value = args[index + 1].trim();
  return value.isEmpty || value.startsWith('--') ? null : value;
}
