// Actual production results, intentionally without assertions or Flutter startup.
import 'dart:convert';
import 'dart:io';
import 'contracts/pattern_registry.g.dart';

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln(
      'Usage: dart run build_tools/export_pattern_contracts.dart OUTPUT.json',
    );
    exitCode = 64;
    return;
  }
  final entries = patternProducers().entries.toList();
  final results = <String, Object?>{};
  // Bounded concurrency avoids paying each placeholder's 100 ms delay serially.
  for (var start = 0; start < entries.length; start += 32) {
    await Future.wait(
      entries.skip(start).take(32).map((entry) async {
        try {
          results[entry.key] = await entry.value();
        } catch (error, stack) {
          results[entry.key] = {'error': '$error', 'stack': '$stack'};
        }
      }),
    );
  }
  final output = File(args.single)..parent.createSync(recursive: true);
  output.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert({'schemaVersion': 1, 'producer': 'dart-production-patterns', 'cases': results})}\n',
  );
  stdout.writeln(
    'Exported ${results.length} production contracts to ${output.path}',
  );
}
