import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Static-hosting entrypoint: link to canonical Python sources, not a fake API.
class ValidationPatternLinks extends StatelessWidget {
  const ValidationPatternLinks({super.key, required this.patternId})
      : assert(patternId >= 91 && patternId <= 99);

  final int patternId;

  static const _names = <String>[
    'ValidationBasic', 'EmailValidation', 'PasswordStrength',
    'PhoneValidation', 'UrlValidation', 'DateValidation',
    'RangeValidation', 'RegexValidation', 'FormValidation',
  ];
  static const _repo =
      'https://github.com/myon-bioinformatics/flutter_navigation_basic/blob/work/pattern-filter-basic-python/';

  @override
  Widget build(BuildContext context) {
    final name = _names[patternId - 91];
    final entries = <(String, String)>[
      ('Python実装', '${_repo}tool/python/validation_patterns.py'),
      ('Pythonテスト', '${_repo}tool/python/tests/test_validation_patterns.py'),
      ('ローカル入力画面', '${_repo}tool/python/validation_http.py'),
      ('利用方法・制約', '${_repo}docs/data-processing-validation-091-099.md'),
    ];
    return Scaffold(
      appBar: AppBar(title: Text('Pattern ${patternId.toString().padLeft(3, '0')}: $name')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('GitHub PagesではPythonを実行できません。実装・テストへのリンクを表示します。'),
          const SizedBox(height: 8),
          const Text('限定実装: Pythonとローカルブラウザで実行可能。Flutterからの検証実行は未接続。'),
          const SizedBox(height: 16),
          for (final (label, url) in entries)
            ListTile(
              title: Text(label),
              subtitle: SelectableText(url),
              trailing: IconButton(
                tooltip: '$label のURLをコピー',
                icon: const Icon(Icons.copy),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: url));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$label のURLをコピーしました')),
                    );
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
