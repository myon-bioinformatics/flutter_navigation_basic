import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Locate the rendered common title independently of emoji decoration. Keep
/// checking the route-specific title text within the stable header region.
Finder pageHeaderTitle(String title) => find.descendant(
  of: find.byWidgetPredicate((widget) => widget is Semantics &&
      widget.properties.identifier == 'shared-header-title'),
  matching: find.textContaining(title),
);
