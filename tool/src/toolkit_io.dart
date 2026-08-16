import 'dart:async';
import 'dart:convert';
import 'dart:io';

class CommandResult {
  CommandResult({
    required this.command,
    required this.exitCode,
    required this.duration,
    required this.stdoutText,
    required this.stderrText,
  });

  final String command;
  final int exitCode;
  final Duration duration;
  final String stdoutText;
  final String stderrText;

  bool get ok => exitCode == 0;
}

Future<CommandResult> runCommand(
  String executable,
  List<String> arguments, {
  bool stream = false,
  Map<String, String>? environment,
}) async {
  final stopwatch = Stopwatch()..start();
  final process = await Process.start(
    executable,
    arguments,
    environment: environment,
    runInShell: Platform.isWindows,
  );

  final stdoutBuffer = StringBuffer();
  final stderrBuffer = StringBuffer();

  final stdoutDone = process.stdout
      .transform(utf8.decoder)
      .listen((chunk) {
        stdoutBuffer.write(chunk);
        if (stream) stdout.write(chunk);
      })
      .asFuture<void>();

  final stderrDone = process.stderr
      .transform(utf8.decoder)
      .listen((chunk) {
        stderrBuffer.write(chunk);
        if (stream) stderr.write(chunk);
      })
      .asFuture<void>();

  final exitCode = await process.exitCode;
  await Future.wait([stdoutDone, stderrDone]);
  stopwatch.stop();

  return CommandResult(
    command: ([executable, ...arguments]).join(' '),
    exitCode: exitCode,
    duration: stopwatch.elapsed,
    stdoutText: stdoutBuffer.toString(),
    stderrText: stderrBuffer.toString(),
  );
}

String formatBytes(int bytes) {
  const units = ['B', 'KiB', 'MiB', 'GiB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value.toStringAsFixed(unit == 0 ? 0 : 2)} ${units[unit]}';
}

String formatDuration(Duration duration) {
  if (duration.inSeconds < 1) return '${duration.inMilliseconds} ms';
  return '${duration.inMilliseconds / 1000.0}s';
}

Future<int> directorySize(
  Directory directory, {
  Set<String> excludedTopLevel = const {},
}) async {
  if (!await directory.exists()) return 0;

  var total = 0;
  await for (final entity in directory.list(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final relative = entity.path
        .replaceFirst('${directory.path}${Platform.pathSeparator}', '');
    final first = relative.split(Platform.pathSeparator).first;
    if (excludedTopLevel.contains(first)) continue;
    try {
      total += await entity.length();
    } on FileSystemException {
      // Ignore files that disappear while inspecting a changing build tree.
    }
  }
  return total;
}

Future<List<File>> dartFilesUnder(Directory directory) async {
  if (!await directory.exists()) return const [];
  final files = <File>[];
  await for (final entity in directory.list(recursive: true, followLinks: false)) {
    if (entity is File && entity.path.endsWith('.dart')) files.add(entity);
  }
  return files;
}

Future<int> countTextOccurrences(Iterable<File> files, String needle) async {
  var count = 0;
  for (final file in files) {
    try {
      final text = await file.readAsString();
      count += RegExp(RegExp.escape(needle)).allMatches(text).length;
    } on FileSystemException {
      // Best-effort repository inspection only.
    }
  }
  return count;
}

Future<int> countFilesContaining(Iterable<File> files, String needle) async {
  var count = 0;
  for (final file in files) {
    try {
      if ((await file.readAsString()).contains(needle)) count++;
    } on FileSystemException {
      // Best-effort repository inspection only.
    }
  }
  return count;
}
