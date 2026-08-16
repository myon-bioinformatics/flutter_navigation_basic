import 'dart:io';

import 'src/toolkit_io.dart';

Future<void> main(List<String> args) async {
  final target = _valueAfter(args, '--target') ?? 'lib/main_prod.dart';
  final diagnosticsDir = Directory(
    _valueAfter(args, '--output-dir') ?? 'build/diagnostics/android-arm64',
  );

  if (await diagnosticsDir.exists()) {
    await diagnosticsDir.delete(recursive: true);
  }
  await diagnosticsDir.create(recursive: true);

  final startedAt = DateTime.now();
  stdout.writeln('=== Android arm64 release size analysis ===');
  stdout.writeln('target: $target');

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
    stream: true,
  );
  if (!build.ok) {
    exitCode = build.exitCode;
    return;
  }

  final apk = File('build/app/outputs/flutter-apk/app-release.apk');
  if (!await apk.exists()) {
    stderr.writeln('Android release APK was not found at ${apk.path}.');
    exitCode = 2;
    return;
  }

  final analysis = await _latestAnalysisFile(startedAt);
  if (analysis == null) {
    stderr.writeln('Flutter code-size analysis JSON was not found under build/.');
    exitCode = 2;
    return;
  }

  final copiedAnalysis = File(
    '${diagnosticsDir.path}/${analysis.uri.pathSegments.last}',
  );
  await analysis.copy(copiedAnalysis.path);

  final metadata = File('${diagnosticsDir.path}/build_meta.json');
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

  final summary = File('${diagnosticsDir.path}/summary.txt');
  final apkBytes = await apk.length();
  final analysisBytes = await copiedAnalysis.length();
  await summary.writeAsString(
    'platform=android-arm64\n'
    'mode=release\n'
    'target=$target\n'
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

Future<File?> _latestAnalysisFile(DateTime startedAt) async {
  final build = Directory('build');
  if (!await build.exists()) return null;

  final candidates = <File>[];
  await for (final entity in build.list(recursive: true, followLinks: false)) {
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
