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

/// Observed (widget kind, id) for a resolved route. An unknown widget keeps its
/// runtime type and id -1, so it can never match a hand-written expectation.
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

void main() {
  // Expected values are written by hand in the manifest; this test only
  // observes what the live route table builds and compares the two.
  final manifest = jsonDecode(
      File('tool/ci/numbered_routes.json').readAsStringSync()) as Map<String, dynamic>;
  final expected = (manifest['routes'] as Map<String, dynamic>).cast<String, String>();

  test('manifest lists exactly /screen001 to /screen198 in order', () {
    expect(expected.keys.toList(),
        [for (var id = 1; id <= 198; id++) id.toString().padLeft(3, '0')]);
  });

  testWidgets('every numbered route builds the expected widget for its own id',
      (tester) async {
    late BuildContext context;
    await tester.pumpWidget(Builder(builder: (c) {
      context = c;
      return const SizedBox();
    }));
    final mismatches = <String>[];
    for (final MapEntry(:key, :value) in expected.entries) {
      final id = int.parse(key);
      final builder = AppRoutes.routes[AppRoutes.screenRoute(id)];
      if (builder == null) {
        mismatches.add('$key: route missing');
        continue;
      }
      final (kind, observedId) = _observe(builder(context));
      if (kind != value || observedId != id) {
        mismatches.add('$key: expected $value#$id, observed $kind#$observedId');
      }
    }
    expect(mismatches, isEmpty);
  });
}
