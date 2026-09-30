import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/now_timeline_models.dart';
import '../domain/zone_table.dart';

/// Await before mounting the app so all synchronous timeline APIs are ready.
Future<void> loadTimeRules() async {
  try {
    final source = await rootBundle.loadString('assets/time/zone_table.json');
    IanaTimeRules.configure(ZoneTable.fromJson(source));
  } catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'Now Timeline bootstrap',
        context: ErrorDescription('loading assets/time/zone_table.json'),
      ),
    );
    rethrow;
  }
}
