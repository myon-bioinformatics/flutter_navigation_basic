import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Static-hosting entrypoint for patterns whose processing lives in Python:
/// shows copyable GitHub links to the real sources instead of a fake "run".
class PatternSourceLinks extends StatelessWidget {
  const PatternSourceLinks({
    super.key,
    required this.patternId,
    required this.name,
    required this.limitation,
    required this.links,
  });

  final int patternId;
  final String name;
  final String limitation;

  /// (label, repository-relative path), in display order.
  final List<(String, String)> links;

  // GitHub Pages builds pass the deployed commit (flutter-pages.yml) so links
  // match the deployed code; builds without SOURCE_REF fall back to main.
  static const _ref = String.fromEnvironment('SOURCE_REF', defaultValue: 'main');
  static const repositoryBase =
      'https://github.com/myon-bioinformatics/flutter_navigation_basic/blob/$_ref/';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pattern ${patternId.toString().padLeft(3, '0')}: $name')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('GitHub PagesではPythonを実行できません。実装・テストへのリンクを表示します。'),
          const SizedBox(height: 8),
          Text(limitation),
          const SizedBox(height: 16),
          for (final (label, path) in links)
            _LinkTile(label: label, url: '$repositoryBase$path'),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) => ListTile(
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
      );
}
