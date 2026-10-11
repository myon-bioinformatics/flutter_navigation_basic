import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_application_1/config/routes.dart';
import 'package:flutter_application_1/core/data_processing/conversion_pattern_links.dart';
import 'package:flutter_application_1/core/data_processing/interactive_pattern_example.dart';
import 'package:flutter_application_1/core/data_processing/native_parallel_pattern_example.dart';
import 'package:flutter_application_1/core/data_processing/validation_pattern_links.dart';
import 'package:flutter_application_1/screens/generic_screen.dart';
import 'package:flutter_test/flutter_test.dart';

/// Observed (widget kind, id). Unknown widgets keep their runtime type and
/// id -1 so they can never match tool/ci/numbered_routes.toml.
(String, int) _observe(Widget widget) => switch (widget) {
      GenericScreen(:final screenId) => ('GenericScreen', screenId),
      InteractivePatternExample(:final patternId) =>
        ('InteractivePatternExample', patternId),
      ValidationPatternLinks(:final patternId) =>
        ('ValidationPatternLinks', patternId),
      ConversionPatternLinks(:final patternId) =>
        ('ConversionPatternLinks', patternId),
      NativeParallelPatternExample(:final patternId) =>
        ('NativeParallelPatternExample', patternId),
      _ => (widget.runtimeType.toString(), -1),
    };

/// Observation only: this test never reads the expected TOML. It records what
/// every /screenN route really builds; tool/python/check_route_observations.py
/// compares that record with the hand-written expectations.
void main() {
  testWidgets('resolve every numbered route and record what it builds',
      (tester) async {
    late BuildContext context;
    await tester.pumpWidget(Builder(builder: (c) {
      context = c;
      return const SizedBox();
    }));
    final numbered = RegExp(r'^/screen(\d+)$');
    final observed = <int, (String, int)>{};
    for (final MapEntry(:key, :value) in AppRoutes.routes.entries) {
      final match = numbered.firstMatch(key);
      if (match != null) observed[int.parse(match[1]!)] = _observe(value(context));
    }

    final ids = observed.keys.toList()..sort();
    final path = Platform.environment['ROUTE_OBSERVATIONS'] ??
        'build/route-observations.json';
    File(path)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert({
        'schema': 'route-observations/1',
        'routes': {
          for (final id in ids)
            id.toString().padLeft(3, '0'): {
              'widget': observed[id]!.$1,
              'id': observed[id]!.$2,
            },
        },
      }));

    // Structural checks that need no expectations at all.
    expect(ids, [for (var id = 1; id <= 198; id++) id],
        reason: 'numbered routes must be exactly /screen1 to /screen198');
    expect(
        [for (final id in ids) if (observed[id]!.$2 != id) id], isEmpty,
        reason: 'each route must build its own id (or an unknown widget was found)');
  });
}
