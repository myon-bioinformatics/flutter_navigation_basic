import 'package:flutter/widgets.dart';

import 'pattern_source_links.dart';

/// 103-105, 107, 109-110: Python conversion producer and its contract docs.
class ConversionPatternLinks extends StatelessWidget {
  // Not const: a map lookup is not a constant expression for the assert.
  ConversionPatternLinks({super.key, required this.patternId})
      : assert(names.containsKey(patternId));

  final int patternId;

  static const names = <int, String>{
    103: 'DataNormalize', 104: 'TypeCoercion', 105: 'DateConvert',
    107: 'UnitConvert', 109: 'Encoding', 110: 'DataMasking',
  };

  @override
  Widget build(BuildContext context) => PatternSourceLinks(
        patternId: patternId,
        name: names[patternId]!,
        limitation: '限定実装: Pythonで実行可能。Flutterからの変換実行は未接続。',
        links: const [
          ('Python実装', 'tool/python/conversion_patterns.py'),
          ('Pythonテスト', 'tool/python/tests/test_conversion_patterns.py'),
          ('利用方法・制約', 'docs/data-processing-conversion-103-110.md'),
        ],
      );
}
