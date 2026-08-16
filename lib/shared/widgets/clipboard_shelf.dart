import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../clipboard/base64_image_bridge.dart';

enum ClipboardShelfKind { text, url, markdown, image }
enum ClipboardShelfSort { newest, oldest, manual }

class ClipboardShelfItem {
  ClipboardShelfItem({
    required this.id,
    required this.kind,
    required this.createdAt,
    this.text,
    this.imageBytes,
    this.mimeType,
  });

  final int id;
  final ClipboardShelfKind kind;
  final DateTime createdAt;
  final String? text;
  final Uint8List? imageBytes;
  final String? mimeType;
}

class ClipboardShelf extends StatefulWidget {
  const ClipboardShelf({super.key});

  @override
  State<ClipboardShelf> createState() => _ClipboardShelfState();
}

class _ClipboardShelfState extends State<ClipboardShelf> {
  static const int _maxImageClipboardChars = 4 * 1024 * 1024;

  final _manualController = TextEditingController();
  final List<ClipboardShelfItem> _items = [];
  final Set<int> _selected = {};
  ClipboardShelfKind? _filter;
  ClipboardShelfSort _sort = ClipboardShelfSort.newest;
  int _nextId = 1;
  String _status = 'Session-only shelf: items disappear when the app/page is restarted.';

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  ClipboardShelfKind _classify(String text) {
    final trimmed = text.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return ClipboardShelfKind.url;
    }
    if (RegExp(r'(^|\n)\s{0,3}(#{1,6}\s|[-*+]\s|>\s|```)', multiLine: true).hasMatch(text) ||
        RegExp(r'\[[^\]]+\]\([^\)]+\)').hasMatch(text)) {
      return ClipboardShelfKind.markdown;
    }
    return ClipboardShelfKind.text;
  }

  void _addText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      setState(() => _status = 'Nothing to add.');
      return;
    }
    setState(() {
      _items.insert(
        0,
        ClipboardShelfItem(
          id: _nextId++,
          kind: _classify(trimmed),
          createdAt: DateTime.now(),
          text: trimmed,
        ),
      );
      _status = 'Added to the in-memory shelf.';
    });
  }

  Future<void> _pasteCurrentClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) {
      setState(() => _status = 'Clipboard does not contain plain text.');
      return;
    }

    final imageCandidate = text.startsWith('data:image/') || _looksLikeRawBase64(text);
    if (imageCandidate && text.length <= _maxImageClipboardChars) {
      try {
        final payload = Base64ImageBridge.decodeText(text);
        final added = await _addImage(payload.bytes, payload.mimeType);
        if (added) return;
      } catch (_) {
        // Preserve the original clipboard value below when image parsing fails.
      }
    }
    _addText(text);
  }

  bool _looksLikeRawBase64(String value) {
    if (value.length < 80 || value.length > _maxImageClipboardChars || value.length % 4 != 0) {
      return false;
    }
    return RegExp(r'^[A-Za-z0-9+/=\r\n]+$').hasMatch(value);
  }

  void _handleInsertedContent(KeyboardInsertedContent content) {
    final bytes = content.data;
    if (bytes == null || bytes.isEmpty || !content.mimeType.startsWith('image/')) {
      setState(() => _status = 'No image bytes were supplied by the platform.');
      return;
    }
    _addImage(bytes, content.mimeType);
  }

  Future<bool> _addImage(Uint8List bytes, String mimeType) async {
    setState(() => _status = 'Preparing image at the default 2/3 scale…');
    try {
      final payload = await Base64ImageBridge.downscaleToPng(bytes);
      if (!mounted) return false;
      setState(() {
        _items.insert(
          0,
          ClipboardShelfItem(
            id: _nextId++,
            kind: ClipboardShelfKind.image,
            createdAt: DateTime.now(),
            imageBytes: payload.bytes,
            mimeType: payload.mimeType,
          ),
        );
        _status = 'Added image after 2/3 resize (${payload.bytes.length} bytes).';
      });
      return true;
    } catch (error) {
      if (!mounted) return false;
      setState(() => _status = 'Image preparation failed; preserved clipboard text instead. ($error)');
      return false;
    }
  }

  List<ClipboardShelfItem> _orderedItems(Iterable<ClipboardShelfItem> source) {
    final values = source.toList();
    if (_sort == ClipboardShelfSort.newest) {
      values.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sort == ClipboardShelfSort.oldest) {
      values.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    return values;
  }

  List<ClipboardShelfItem> get _visibleItems =>
      _orderedItems(_items.where((item) => _filter == null || item.kind == _filter));

  String _plainText(String markdown) {
    var text = markdown;
    text = text.replaceAll(RegExp(r'^\s{0,3}#{1,6}\s+', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^\s{0,3}>\s?', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^\s*\d+[.)]\s+', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^\s*```[^\n]*$', multiLine: true), '');
    text = text.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\(([^\)]+)\)'),
      (m) => '${m[1]} (${m[2]})',
    );
    text = text.replaceAllMapped(RegExp(r'`([^`\n]+)`'), (m) => m[1] ?? '');
    text = text.replaceAllMapped(RegExp(r'\*\*([^*\n]+)\*\*'), (m) => m[1] ?? '');
    text = text.replaceAllMapped(RegExp(r'~~([^~\n]+)~~'), (m) => m[1] ?? '');
    return text.trim();
  }

  Future<void> _copyItem(ClipboardShelfItem item, {bool plain = false}) async {
    final text = switch (item.kind) {
      ClipboardShelfKind.image => Base64ImagePayload(
          bytes: item.imageBytes!,
          mimeType: item.mimeType ?? 'image/png',
        ).dataUrl,
      ClipboardShelfKind.markdown when plain => _plainText(item.text ?? ''),
      _ => item.text ?? '',
    };
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _status = plain ? 'Copied plain text.' : 'Copied raw item.');
  }

  String _bundleText() {
    final ordered = _selected.isEmpty
        ? _visibleItems
        : _orderedItems(_items.where((item) => _selected.contains(item.id)));
    final buffer = StringBuffer('# Context Bundle\n\n');
    for (var i = 0; i < ordered.length; i++) {
      final item = ordered[i];
      buffer.writeln('## ${i + 1}. ${_kindLabel(item.kind)}');
      if (item.kind == ClipboardShelfKind.image) {
        buffer.writeln(Base64ImagePayload(
          bytes: item.imageBytes!,
          mimeType: item.mimeType ?? 'image/png',
        ).dataUrl);
      } else {
        buffer.writeln(item.text ?? '');
      }
      buffer.writeln();
    }
    return buffer.toString().trimRight();
  }

  Future<void> _copyBundle() async {
    if (_items.isEmpty) {
      setState(() => _status = 'Shelf is empty.');
      return;
    }
    final text = _bundleText();
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _status = 'Copied context bundle (${text.length} characters).');
  }

  void _moveManual(int id, int delta) {
    final visibleBefore = _visibleItems;
    final visibleIndex = visibleBefore.indexWhere((item) => item.id == id);
    final targetVisibleIndex = visibleIndex + delta;
    if (visibleIndex < 0 || targetVisibleIndex < 0 || targetVisibleIndex >= visibleBefore.length) {
      return;
    }

    final targetId = visibleBefore[targetVisibleIndex].id;
    setState(() {
      if (_sort != ClipboardShelfSort.manual) {
        final normalized = _orderedItems(_items);
        _items
          ..clear()
          ..addAll(normalized);
      }
      final index = _items.indexWhere((item) => item.id == id);
      final targetIndex = _items.indexWhere((item) => item.id == targetId);
      if (index < 0 || targetIndex < 0) return;
      final current = _items[index];
      _items[index] = _items[targetIndex];
      _items[targetIndex] = current;
      _sort = ClipboardShelfSort.manual;
      _status = 'Switched to manual order.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleItems;
    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Core Tool #1 · Clipboard Shelf', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  const Text('Temporary, session-only clipboard history for text, URLs, Markdown and lightweight image transport.'),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _manualController,
                    minLines: 2,
                    maxLines: 5,
                    contentInsertionConfiguration: ContentInsertionConfiguration(
                      onContentInserted: _handleInsertedContent,
                      allowedMimeTypes: const ['image/png', 'image/jpeg', 'image/webp'],
                    ),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Add text / URL / Markdown',
                      hintText: 'Paste or type something, then add it to the shelf. Rich image insertion is accepted where the platform supplies bytes.',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: _pasteCurrentClipboard,
                        icon: const Icon(Icons.content_paste_go_outlined),
                        label: const Text('Paste current clipboard'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          _addText(_manualController.text);
                          _manualController.clear();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add manually'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _copyBundle,
                        icon: const Icon(Icons.copy_all_outlined),
                        label: Text(_selected.isEmpty ? 'Copy visible bundle' : 'Copy selected bundle (${_selected.length})'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DropdownButton<ClipboardShelfSort>(
                value: _sort,
                items: const [
                  DropdownMenuItem(value: ClipboardShelfSort.newest, child: Text('Newest first')),
                  DropdownMenuItem(value: ClipboardShelfSort.oldest, child: Text('Oldest first')),
                  DropdownMenuItem(value: ClipboardShelfSort.manual, child: Text('Manual order')),
                ],
                onChanged: (value) => setState(() => _sort = value ?? ClipboardShelfSort.newest),
              ),
              FilterChip(label: const Text('All'), selected: _filter == null, onSelected: (_) => setState(() => _filter = null)),
              for (final kind in ClipboardShelfKind.values)
                FilterChip(
                  label: Text(_kindLabel(kind)),
                  selected: _filter == kind,
                  onSelected: (_) => setState(() => _filter = _filter == kind ? null : kind),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('Shelf is empty for this filter.')))
          else
            for (final item in visible) ...[
              _ShelfItemCard(
                item: item,
                selected: _selected.contains(item.id),
                plainText: item.kind == ClipboardShelfKind.markdown ? _plainText(item.text ?? '') : null,
                onSelected: (value) => setState(() {
                  if (value) {
                    _selected.add(item.id);
                  } else {
                    _selected.remove(item.id);
                  }
                }),
                onCopyRaw: () => _copyItem(item),
                onCopyPlain: item.kind == ClipboardShelfKind.markdown ? () => _copyItem(item, plain: true) : null,
                onMoveUp: () => _moveManual(item.id, -1),
                onMoveDown: () => _moveManual(item.id, 1),
                onDelete: () => setState(() {
                  _selected.remove(item.id);
                  _items.removeWhere((candidate) => candidate.id == item.id);
                }),
              ),
              const SizedBox(height: 8),
            ],
          const SizedBox(height: 8),
          Semantics(liveRegion: true, child: Text(_status, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}

String _kindLabel(ClipboardShelfKind kind) => switch (kind) {
      ClipboardShelfKind.text => 'Text',
      ClipboardShelfKind.url => 'URL',
      ClipboardShelfKind.markdown => 'Markdown',
      ClipboardShelfKind.image => 'Image',
    };

class _ShelfItemCard extends StatelessWidget {
  const _ShelfItemCard({
    required this.item,
    required this.selected,
    required this.plainText,
    required this.onSelected,
    required this.onCopyRaw,
    required this.onCopyPlain,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDelete,
  });

  final ClipboardShelfItem item;
  final bool selected;
  final String? plainText;
  final ValueChanged<bool> onSelected;
  final VoidCallback onCopyRaw;
  final VoidCallback? onCopyPlain;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Checkbox(value: selected, onChanged: (value) => onSelected(value ?? false)),
                Text(_kindLabel(item.kind), style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                IconButton(onPressed: onMoveUp, tooltip: 'Move up', icon: const Icon(Icons.arrow_upward)),
                IconButton(onPressed: onMoveDown, tooltip: 'Move down', icon: const Icon(Icons.arrow_downward)),
                IconButton(onPressed: onDelete, tooltip: 'Delete', icon: const Icon(Icons.delete_outline)),
              ],
            ),
            if (item.kind == ClipboardShelfKind.image)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  item.imageBytes!,
                  height: 180,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(height: 80, child: Center(child: Text('Preview unavailable'))),
                ),
              )
            else
              SelectableText(item.text ?? ''),
            if (plainText != null) ...[
              const SizedBox(height: 8),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Plain preview'),
                children: [Align(alignment: Alignment.centerLeft, child: SelectableText(plainText!))],
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(onPressed: onCopyRaw, icon: const Icon(Icons.copy, size: 16), label: const Text('Copy raw')),
                if (onCopyPlain != null)
                  OutlinedButton.icon(onPressed: onCopyPlain, icon: const Icon(Icons.notes, size: 16), label: const Text('Copy plain')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
