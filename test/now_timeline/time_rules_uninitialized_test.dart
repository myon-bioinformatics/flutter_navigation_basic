import 'package:flutter_application_1/features/now_timeline/domain/now_timeline_models.dart';
import 'package:flutter_test/flutter_test.dart';

// Separate test isolate, with no configuration or global reset API.
void main() {
  test('all conversion APIs fail before configure', () {
    final utc = DateTime.utc(2026);
    expect(() => IanaTimeRules.lookupAtUtc('Asia/Tokyo', utc), throwsStateError);
    expect(() => IanaTimeRules.offsetMinutesAtUtc('Asia/Tokyo', utc), throwsStateError);
    expect(() => IanaTimeRules.toLocal('Asia/Tokyo', utc), throwsStateError);
    expect(() => IanaTimeRules.isDst('Asia/Tokyo', utc), throwsStateError);
    expect(() => IanaTimeRules.localWallTimeToUtc('Asia/Tokyo', utc), throwsStateError);
  });
}
