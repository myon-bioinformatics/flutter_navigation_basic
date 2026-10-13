import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../display/display_scope.dart';

// Standalone widgets without an app DisplayScope retain their English UI.
// The scoped app path always resolves through the existing locale catalog.
const _standaloneText = <String, String>{
  "sessionClipboard.title": "Temporary clipboard",
  "sessionClipboard.subtitle": "Text only \u00b7 kept until page reload",
  "sessionClipboard.save": "Save copied text",
  "sessionClipboard.empty": "Nothing saved yet",
  "sessionClipboard.copy": "Copy saved text",
  "sessionClipboard.noText": "No copied text to save",
  "sessionClipboard.saved": "Saved to temporary clipboard",
  "sessionClipboard.tooLarge": "Text is too large to save",
  "sessionClipboard.readFailed": "Cannot read system clipboard",
  "sessionClipboard.copied": "Copied to system clipboard",
  "sessionClipboard.copyFailed": "Cannot copy to system clipboard",
};

String _text(BuildContext context, String key) =>
    DisplayScope.maybeOf(context)?.text(key) ?? _standaloneText[key] ?? key;

/// Volatile app-session text clipboard. No disk, preferences or web storage.
/// A full page reload resets this static state, while navigation preserves it.
class SessionTextClipboard {
  SessionTextClipboard._();
  static final ValueNotifier<List<String>> entries = ValueNotifier([]);
  static const maxEntries = 30;
  static const maxChars = 100000;

  static bool save(String text) {
    if (text.isEmpty || text.length > maxChars) return false;
    entries.value = [
      text,
      ...entries.value.where((item) => item != text),
    ].take(maxEntries).toList(growable: false);
    return true;
  }

  static void clear() => entries.value = [];
}

class SessionClipboardDrawerSection extends StatefulWidget {
  const SessionClipboardDrawerSection({super.key});

  @override
  State<SessionClipboardDrawerSection> createState() =>
      _SessionClipboardDrawerSectionState();
}

class _SessionClipboardDrawerSectionState
    extends State<SessionClipboardDrawerSection> {
  // Store the result key so an existing notification follows locale changes.
  String? _feedback;

  Future<void> _saveFromSystemClipboard() async {
    try {
      final value = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
      if (!mounted) return;
      setState(() {
        _feedback = value == null || value.isEmpty
            ? 'sessionClipboard.noText'
            : SessionTextClipboard.save(value)
            ? 'sessionClipboard.saved'
            : 'sessionClipboard.tooLarge';
      });
    } catch (_) {
      if (mounted) setState(() => _feedback = 'sessionClipboard.readFailed');
    }
  }

  Future<void> _copy(String value) async {
    try {
      await Clipboard.setData(ClipboardData(text: value));
      if (mounted) setState(() => _feedback = 'sessionClipboard.copied');
    } catch (_) {
      if (mounted) setState(() => _feedback = 'sessionClipboard.copyFailed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: const Icon(Icons.content_paste_outlined),
          title: Text(_text(context, 'sessionClipboard.title')),
          subtitle: Text(_text(context, 'sessionClipboard.subtitle')),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FilledButton.icon(
            key: const Key('session-clipboard-save'),
            onPressed: _saveFromSystemClipboard,
            icon: const Icon(Icons.save_outlined),
            label: Text(_text(context, 'sessionClipboard.save')),
          ),
        ),
        if (_feedback != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              _text(context, _feedback!),
              key: const Key('session-clipboard-feedback'),
            ),
          ),
        ValueListenableBuilder<List<String>>(
          valueListenable: SessionTextClipboard.entries,
          builder: (context, saved, _) => Column(
            children: [
              if (saved.isEmpty)
                ListTile(title: Text(_text(context, 'sessionClipboard.empty'))),
              for (var i = 0; i < saved.length; i++)
                ListTile(
                  key: Key('session-clipboard-entry-$i'),
                  title: Text(
                    saved[i],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    key: Key('session-clipboard-copy-$i'),
                    tooltip: _text(context, 'sessionClipboard.copy'),
                    onPressed: () => _copy(saved[i]),
                    icon: const Icon(Icons.copy_outlined),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
