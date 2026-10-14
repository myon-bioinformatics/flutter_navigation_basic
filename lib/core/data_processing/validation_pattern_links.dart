import 'package:flutter/widgets.dart';

import 'pattern_source_links.dart';

/// 091-099: Python validation producer, local HTTP form and docs.
class ValidationPatternLinks extends StatelessWidget {
  const ValidationPatternLinks({super.key, required this.patternId})
      : assert(patternId >= 91 && patternId <= 99);

  final int patternId;

  static const _names = <String>[
    'ValidationBasic', 'EmailValidation', 'PasswordStrength',
    'PhoneValidation', 'UrlValidation', 'DateValidation',
    'RangeValidation', 'RegexValidation', 'FormValidation',
  ];

  @override
  Widget build(BuildContext context) => PatternSourceLinks(
        patternId: patternId,
        name: _names[patternId - 91],
        limitation: '限定実装: Pythonとローカルブラウザで実行可能。Flutterからの検証実行は未接続。',
        links: const [
          ('Python実装', 'python/validation_patterns.py'),
          ('Pythonテスト', 'python/tests/test_validation_patterns.py'),
          ('ローカル入力画面', 'python/validation_http.py'),
          ('利用方法・制約', 'docs/data-processing-validation-091-099.md'),
        ],
      );
}
