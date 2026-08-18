import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../clipboard/base64_image_bridge.dart';
import '../display/display_scope.dart';

class ClipboardPromptWorkbench extends StatefulWidget {
  const ClipboardPromptWorkbench({super.key});

  @override
  State<ClipboardPromptWorkbench> createState() => _ClipboardPromptWorkbenchState();
}

class _ClipboardPromptWorkbenchState extends State<ClipboardPromptWorkbench> {
  static const int _maxBase64TextChars = 16 * 1024 * 1024;

  final _rawController = TextEditingController();
  final _goalController = TextEditingController();
  final _contextController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _constraintsController = TextEditingController();
  final _outputController = TextEditingController();
  final _base64Controller = TextEditingController();

  Uint8List? _imageBytes;
  String? _imageMimeType;
  bool _processingImage = false;
  String _statusKey = 'clipboardWorkbench.status.initial';
  Map<String, Object?> _statusArgs = const {};

  @override
  void dispose() {
    _rawController.dispose();
    _goalController.dispose();
    _contextController.dispose();
    _requirementsController.dispose();
    _constraintsController.dispose();
    _outputController.dispose();
    _base64Controller.dispose();
    super.dispose();
  }

  Future<void> _pasteText() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (!mounted) return;
    if (text == null || text.trim().isEmpty) {
      setState(() {
        _statusKey = 'clipboardWorkbench.status.noClipboardText';
        _statusArgs = const {};
      });
      return;
    }
    _rawController.text = text;
    setState(() {
      _statusKey = 'clipboardWorkbench.status.pasted';
      _statusArgs = {'chars': text.length};
    });
  }

  Future<void> _copyPrompt() async {
    final prompt = _buildPrompt();
    await Clipboard.setData(ClipboardData(text: prompt));
    if (!mounted) return;
    setState(() {
      _statusKey = 'clipboardWorkbench.status.copiedPrompt';
      _statusArgs = {'chars': prompt.length};
    });
  }

  void _handleInsertedContent(KeyboardInsertedContent content) {
    final bytes = content.data;
    if (bytes == null || bytes.isEmpty || !content.mimeType.startsWith('image/')) {
      setState(() {
        _statusKey = 'clipboardWorkbench.status.noImageBytes';
        _statusArgs = const {};
      });
      return;
    }
    setState(() {
      _imageBytes = bytes;
      _imageMimeType = content.mimeType;
      _statusKey = 'clipboardWorkbench.status.attached';
      _statusArgs = {'mimeType': content.mimeType, 'bytes': bytes.length};
    });
  }

  Future<void> _copyImageAsBase64() async {
    final bytes = _imageBytes;
    if (bytes == null) {
      setState(() {
        _statusKey = 'clipboardWorkbench.status.noImageToEncode';
        _statusArgs = const {};
      });
      return;
    }
    setState(() => _processingImage = true);
    try {
      final payload = await Base64ImageBridge.downscaleToPng(bytes);
      final text = payload.dataUrl;
      await Clipboard.setData(ClipboardData(text: text));
      _base64Controller.text = text;
      if (!mounted) return;
      setState(() {
        _processingImage = false;
        _statusKey = 'clipboardWorkbench.status.encoded';
        _statusArgs = {'bytes': payload.bytes.length};
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _processingImage = false;
        _statusKey = 'clipboardWorkbench.status.encodeFailed';
        _statusArgs = {'error': error};
      });
    }
  }

  Future<void> _pasteBase64Image() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final text = data?.text ?? '';
    if (text.trim().isEmpty) {
      setState(() {
        _statusKey = 'clipboardWorkbench.status.noBase64Text';
        _statusArgs = const {};
      });
      return;
    }
    if (text.length > _maxBase64TextChars) {
      setState(() {
        _statusKey = 'clipboardWorkbench.status.base64TooLargeClipboard';
        _statusArgs = {'chars': text.length, 'limit': _maxBase64TextChars};
      });
      return;
    }
    _base64Controller.text = text;
    _decodeBase64Image();
  }

  void _decodeBase64Image() {
    final input = _base64Controller.text;
    if (input.length > _maxBase64TextChars) {
      setState(() {
        _statusKey = 'clipboardWorkbench.status.base64TooLarge';
        _statusArgs = {'chars': input.length, 'limit': _maxBase64TextChars};
      });
      return;
    }
    try {
      final payload = Base64ImageBridge.decodeText(input);
      setState(() {
        _imageBytes = payload.bytes;
        _imageMimeType = payload.mimeType;
        _statusKey = 'clipboardWorkbench.status.decoded';
        _statusArgs = {'mimeType': payload.mimeType, 'bytes': payload.bytes.length};
      });
    } catch (error) {
      setState(() {
        _statusKey = 'clipboardWorkbench.status.decodeFailed';
        _statusArgs = {'error': error};
      });
    }
  }

  String _buildPrompt() {
    String section(String title, String value) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? '' : '## $title\n$trimmed\n\n';
    }

    final buffer = StringBuffer()
      ..writeln('# System Prompt Draft')
      ..writeln()
      ..write(section('Goal', _goalController.text))
      ..write(section('Context / reference material', _contextController.text))
      ..write(section('Must include', _requirementsController.text))
      ..write(section('Constraints / avoid', _constraintsController.text))
      ..write(section('Output format', _outputController.text))
      ..write(section('Raw source', _rawController.text));

    if (_imageBytes != null) {
      buffer
        ..writeln('## Visual reference')
        ..writeln('An image reference is attached in the workbench (${_imageMimeType ?? 'image'}, ${_imageBytes!.length} bytes).')
        ..writeln('Use its layout/content as visual context when the receiving system supports image input.')
        ..writeln();
    }
    return buffer.toString().trimRight();
  }

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    final preview = _buildPrompt();
    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepCard(
            number: 1,
            title: display.text('clipboardWorkbench.step1.title'),
            subtitle: display.text('clipboardWorkbench.step1.subtitle'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _rawController,
                  minLines: 4,
                  maxLines: 10,
                  onChanged: (_) => setState(() {}),
                  contentInsertionConfiguration: ContentInsertionConfiguration(
                    onContentInserted: _handleInsertedContent,
                    allowedMimeTypes: const ['image/png', 'image/jpeg', 'image/webp'],
                  ),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: display.text('clipboardWorkbench.step1.fieldLabel'),
                    hintText: display.text('clipboardWorkbench.step1.fieldHint'),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _pasteText,
                      icon: const Icon(Icons.content_paste_go_outlined),
                      label: Text(display.text('clipboardWorkbench.pasteText')),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        _rawController.clear();
                        setState(() {
                          _statusKey = 'clipboardWorkbench.status.cleared';
                          _statusArgs = const {};
                        });
                      },
                      icon: const Icon(Icons.clear),
                      label: Text(display.text('clipboardWorkbench.clear')),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _StepCard(
            number: 2,
            title: display.text('clipboardWorkbench.step2.title'),
            subtitle: display.text('clipboardWorkbench.step2.subtitle'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ImageReferenceCard(
                  bytes: _imageBytes,
                  mimeType: _imageMimeType,
                  onRemove: _imageBytes == null
                      ? null
                      : () => setState(() {
                            _imageBytes = null;
                            _imageMimeType = null;
                            _statusKey = 'clipboardWorkbench.status.removedImage';
                            _statusArgs = const {};
                          }),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _base64Controller,
                  minLines: 2,
                  maxLines: 5,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: display.text('clipboardWorkbench.step2.fieldLabel'),
                    hintText: display.text('clipboardWorkbench.step2.fieldHint'),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _processingImage ? null : _copyImageAsBase64,
                      icon: const Icon(Icons.copy_all_outlined),
                      label: Text(
                        _processingImage
                            ? display.text('clipboardWorkbench.copyImageBase64Encoding')
                            : display.text('clipboardWorkbench.copyImageBase64'),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pasteBase64Image,
                      icon: const Icon(Icons.content_paste_outlined),
                      label: Text(display.text('clipboardWorkbench.pasteBase64Image')),
                    ),
                    OutlinedButton.icon(
                      onPressed: _decodeBase64Image,
                      icon: const Icon(Icons.image_search_outlined),
                      label: Text(display.text('clipboardWorkbench.decodePreview')),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _StepCard(
            number: 3,
            title: display.text('clipboardWorkbench.step3.title'),
            subtitle: display.text('clipboardWorkbench.step3.subtitle'),
            child: Column(
              children: [
                _Field(
                  controller: _goalController,
                  label: display.text('clipboardWorkbench.field.goal.label'),
                  hint: display.text('clipboardWorkbench.field.goal.hint'),
                  onChanged: () => setState(() {}),
                ),
                _Field(
                  controller: _contextController,
                  label: display.text('clipboardWorkbench.field.context.label'),
                  hint: display.text('clipboardWorkbench.field.context.hint'),
                  onChanged: () => setState(() {}),
                ),
                _Field(
                  controller: _requirementsController,
                  label: display.text('clipboardWorkbench.field.requirements.label'),
                  hint: display.text('clipboardWorkbench.field.requirements.hint'),
                  onChanged: () => setState(() {}),
                ),
                _Field(
                  controller: _constraintsController,
                  label: display.text('clipboardWorkbench.field.constraints.label'),
                  hint: display.text('clipboardWorkbench.field.constraints.hint'),
                  onChanged: () => setState(() {}),
                ),
                _Field(
                  controller: _outputController,
                  label: display.text('clipboardWorkbench.field.output.label'),
                  hint: display.text('clipboardWorkbench.field.output.hint'),
                  onChanged: () => setState(() {}),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _StepCard(
            number: 4,
            title: display.text('clipboardWorkbench.step4.title'),
            subtitle: display.text('clipboardWorkbench.step4.subtitle'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  constraints: const BoxConstraints(maxHeight: 360),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      preview.isEmpty ? '# System Prompt Draft' : preview,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _copyPrompt,
                  icon: const Icon(Icons.copy_all_outlined),
                  label: Text(display.text('clipboardWorkbench.copyPrompt')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(display.text(_statusKey, arguments: _statusArgs), style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _ImageReferenceCard extends StatelessWidget {
  const _ImageReferenceCard({
    required this.bytes,
    required this.mimeType,
    required this.onRemove,
  });

  final Uint8List? bytes;
  final String? mimeType;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    if (bytes == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.image_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Text(display.text('clipboardWorkbench.imageReference.placeholder')),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            bytes!,
            height: 220,
            width: double.infinity,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return SizedBox(
                height: 120,
                child: Center(
                  child: Text(display.text('clipboardWorkbench.imageReference.previewUnavailable')),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                display.text(
                  'clipboardWorkbench.imageReference.meta',
                  arguments: {
                    'mimeType': mimeType ?? display.text('clipboardWorkbench.imageReference.unknownMime'),
                    'bytes': bytes!.length,
                  },
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline),
              label: Text(display.text('clipboardWorkbench.imageReference.remove')),
            ),
          ],
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.label, required this.hint, required this.onChanged});

  final TextEditingController controller;
  final String label;
  final String hint;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        minLines: 2,
        maxLines: 5,
        onChanged: (_) => onChanged(),
        decoration: InputDecoration(border: const OutlineInputBorder(), labelText: label, hintText: hint),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.number, required this.title, required this.subtitle, required this.child});

  final int number;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(radius: 16, child: Text('$number')),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 3),
                      Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
