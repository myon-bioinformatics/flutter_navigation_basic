// Pattern 001: FilterBasic
// Shared runtime operation for the Flutter catalogue boundary.
import 'package:flutter_application_1/core/data_processing/list_filters.dart';
import 'model.dart';

class Pattern001Service {
  Future<Pattern001Result> run() async {
    final filtered = filterEquals<int>(const [1, 2, 1, 3], 1);
    return Pattern001Result(message: 'FilterBasic: $filtered');
  }
}
