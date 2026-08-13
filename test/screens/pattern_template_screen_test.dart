import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/screens/pattern_template_screen.dart';

void main() {
  test('198 screens are distributed across 11 templates in blocks of 18', () {
    expect(PatternScreenTemplate.values, hasLength(11));

    for (var templateIndex = 0; templateIndex < 11; templateIndex++) {
      final firstId = templateIndex * 18 + 1;
      final lastId = firstId + 17;
      expect(templateForScreenId(firstId), PatternScreenTemplate.values[templateIndex]);
      expect(templateForScreenId(lastId), PatternScreenTemplate.values[templateIndex]);
    }

    expect(templateForScreenId(1), PatternScreenTemplate.list);
    expect(templateForScreenId(198), PatternScreenTemplate.settings);
  });

  test('templateFromName resolves known names and falls back safely', () {
    expect(templateFromName('detail'), PatternScreenTemplate.detail);
    expect(templateFromName('bottomNavigation'), PatternScreenTemplate.bottomNavigation);
    expect(templateFromName('settings'), PatternScreenTemplate.settings);
    expect(templateFromName('unknown-template'), PatternScreenTemplate.list);
    expect(templateFromName(null), PatternScreenTemplate.list);
  });
}
