import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../clipboard/base64_image_bridge.dart';
import '../display/display_scope.dart';

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
  String _statusKey = 'clipboardShelf.status.initial';
  Map<String, Object?> _statusArgs = const {};

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
      setState(() {
        _statusKey = 'clipboardShelf.status.nothingToAdd';
        _statusArgs = const {};
      });
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
      _statusKey = 'clipboardShelf.status.added';
      _statusArgs = const {};
    });
  }

  Future<void> _pasteCurrentClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) {
      setState(() {
        _statusKey = 'clipboardShelf.status.noClipboardText';
        _statusArgs = const {};
      });
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
      setState(() {
        _statusKey = 'clipboardShelf.status.noImageBytes';
        _statusArgs = const {};
      });
      return;
    }
    _addImage(bytes, content.mimeType);
  }

  Future<bool> _addImage(Uint8List bytes, String mimeType) async {
    setState(() {
      _statusKey = 'clipboardShelf.status.preparingImage';
      _statusArgs = const {};
    });
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
        _statusKey = 'clipboardShelf.status.imageAdded';
        _statusArgs = {'bytes': payload.bytes.length};
      });
      return true;
    } catch (error) {
      if (!mounted) return false;
      setState(() {
        _statusKey = 'clipboardShelf.status.imageFailed';
        _statusArgs = {'error': error};
      });
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
    setState(() {
      _statusKey = plain ? 'clipboardShelf.status.copiedPlain' : 'clipboardShelf.status.copiedRaw';
      _statusArgs = const {};
    });
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
      setState(() {
        _statusKey = 'clipboardShelf.status.shelfEmpty';
        _statusArgs = const {};
      });
      return;
    }
    final text = _bundleText();
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() {
      _statusKey = 'clipboardShelf.status.copiedBundle';
      _statusArgs = {'chars': text.length};
    });
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
      _statusKey = 'clipboardShelf.status.manualOrder';
      _statusArgs = const {};
    });
  }

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
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
                  Text(display.text('clipboardShelf.title'), style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(display.text('clipboardShelf.subtitle')),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _manualController,
                    minLines: 2,
                    maxLines: 5,
                    contentInsertionConfiguration: ContentInsertionConfiguration(
                      onContentInserted: _handleInsertedContent,
                      allowedMimeTypes: const ['image/png', 'image/jpeg', 'image/webp'],
                    ),
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: display.text('clipboardShelf.addLabel'),
                      hintText: display.text('clipboardShelf.addHint'),
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
                        label: Text(display.text('clipboardShelf.pasteClipboard')),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          _addText(_manualController.text);
                          _manualController.clear();
                        },
                        icon: const Icon(Icons.add),
                        label: Text(display.text('clipboardShelf.addManually')),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _copyBundle,
                        icon: const Icon(Icons.copy_all_outlined),
                        label: Text(
                          _selected.isEmpty
                              ? display.text('clipboardShelf.copyVisibleBundle')
                              : display.text('clipboardShelf.copySelectedBundle', arguments: {'count': _selected.length}),
                        ),
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
                items: [
                  DropdownMenuItem(value: ClipboardShelfSort.newest, child: Text(display.text('clipboardShelf.sortNewest'))),
                  DropdownMenuItem(value: ClipboardShelfSort.oldest, child: Text(display.text('clipboardShelf.sortOldest'))),
                  DropdownMenuItem(value: ClipboardShelfSort.manual, child: Text(display.text('clipboardShelf.sortManual'))),
                ],
                onChanged: (value) => setState(() => _sort = value ?? ClipboardShelfSort.newest),
              ),
              FilterChip(
                label: Text(display.text('clipboardShelf.filterAll')),
                selected: _filter == null,
                onSelected: (_) => setState(() => _filter = null),
              ),
              for (final kind in ClipboardShelfKind.values)
                FilterChip(
                  label: Text(_kindDisplayLabel(display, kind)),
                  selected: _filter == kind,
                  onSelected: (_) => setState(() => _filter = _filter == kind ? null : kind),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            Card(child: Padding(padding: const EdgeInsets.all(24), child: Text(display.text('clipboardShelf.emptyFilter'))))
          else
            for (final item in visible) ...[
              _ShelfItemCard(
                item: item,
                selected: _selected.contains(item.id),
                plainText: item.kind == ClipboardShelfKind.markdown ? _plainText(item.text ?? '') : null,
                kindLabel: _kindDisplayLabel(display, item.kind),
                moveUpTooltip: display.text('clipboardShelf.moveUp'),
                moveDownTooltip: display.text('clipboardShelf.moveDown'),
                deleteTooltip: display.text('clipboardShelf.delete'),
                plainPreviewLabel: display.text('clipboardShelf.plainPreview'),
                previewUnavailableLabel: display.text('clipboardShelf.previewUnavailable'),
                copyRawLabel: display.text('clipboardShelf.copyRaw'),
                copyPlainLabel: display.text('clipboardShelf.copyPlain'),
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
          Semantics(
            liveRegion: true,
            child: Text(display.text(_statusKey, arguments: _statusArgs), style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

// Fixed English labels used only inside the copied bundle payload (_bundleText());
// that text is a "generated content / copied payload" and stays literal regardless
// of locale, unlike the translated UI labels from _kindDisplayLabel below.
String _kindLabel(ClipboardShelfKind kind) => switch (kind) {
      ClipboardShelfKind.text => 'Text',
      ClipboardShelfKind.url => 'URL',
      ClipboardShelfKind.markdown => 'Markdown',
      ClipboardShelfKind.image => 'Image',
    };

String _kindDisplayLabel(DisplayController display, ClipboardShelfKind kind) => switch (kind) {
      ClipboardShelfKind.text => display.text('clipboardShelf.kind.text'),
      ClipboardShelfKind.url => display.text('clipboardShelf.kind.url'),
      ClipboardShelfKind.markdown => display.text('clipboardShelf.kind.markdown'),
      ClipboardShelfKind.image => display.text('clipboardShelf.kind.image'),
    };

class _ShelfItemCard extends StatelessWidget {
  const _ShelfItemCard({
    required this.item,
    required this.selected,
    required this.plainText,
    required this.kindLabel,
    required this.moveUpTooltip,
    required this.moveDownTooltip,
    required this.deleteTooltip,
    required this.plainPreviewLabel,
    required this.previewUnavailableLabel,
    required this.copyRawLabel,
    required this.copyPlainLabel,
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
  final String kindLabel;
  final String moveUpTooltip;
  final String moveDownTooltip;
  final String deleteTooltip;
  final String plainPreviewLabel;
  final String previewUnavailableLabel;
  final String copyRawLabel;
  final String copyPlainLabel;
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
                Text(kindLabel, style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                IconButton(onPressed: onMoveUp, tooltip: moveUpTooltip, icon: const Icon(Icons.arrow_upward)),
                IconButton(onPressed: onMoveDown, tooltip: moveDownTooltip, icon: const Icon(Icons.arrow_downward)),
                IconButton(onPressed: onDelete, tooltip: deleteTooltip, icon: const Icon(Icons.delete_outline)),
              ],
            ),
            if (item.kind == ClipboardShelfKind.image)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  item.imageBytes!,
                  height: 180,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => SizedBox(height: 80, child: Center(child: Text(previewUnavailableLabel))),
                ),
              )
            else
              SelectableText(item.text ?? ''),
            if (plainText != null) ...[
              const SizedBox(height: 8),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(plainPreviewLabel),
                children: [Align(alignment: Alignment.centerLeft, child: SelectableText(plainText!))],
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(onPressed: onCopyRaw, icon: const Icon(Icons.copy, size: 16), label: Text(copyRawLabel)),
                if (onCopyPlain != null)
                  OutlinedButton.icon(onPressed: onCopyPlain, icon: const Icon(Icons.notes, size: 16), label: Text(copyPlainLabel)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
