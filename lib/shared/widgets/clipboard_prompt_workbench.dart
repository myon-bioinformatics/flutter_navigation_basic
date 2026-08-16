import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ClipboardPromptWorkbench extends StatefulWidget {
  const ClipboardPromptWorkbench({super.key});

  @override
  State<ClipboardPromptWorkbench> createState() => _ClipboardPromptWorkbenchState();
}

class _ClipboardPromptWorkbenchState extends State<ClipboardPromptWorkbench> {
  final _rawController = TextEditingController();
  final _goalController = TextEditingController();
  final _contextController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _constraintsController = TextEditingController();
  final _outputController = TextEditingController();

  Uint8List? _imageBytes;
  String? _imageMimeType;
  String _status = 'Paste text first, then shape it into a reusable system prompt.';

  @override
  void dispose() {
    _rawController.dispose();
    _goalController.dispose();
    _contextController.dispose();
    _requirementsController.dispose();
    _constraintsController.dispose();
    _outputController.dispose();
    super.dispose();
  }

  Future<void> _pasteText() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (!mounted) return;
    if (text == null || text.trim().isEmpty) {
      setState(() => _status = 'Clipboard does not contain plain text.');
      return;
    }
    _rawController.text = text;
    setState(() => _status = 'Pasted ${text.length} characters from the clipboard.');
  }

  Future<void> _copyPrompt() async {
    final prompt = _buildPrompt();
    await Clipboard.setData(ClipboardData(text: prompt));
    if (!mounted) return;
    setState(() => _status = 'Copied the composed system prompt (${prompt.length} characters).');
  }

  void _handleInsertedContent(KeyboardInsertedContent content) {
    final bytes = content.data;
    if (bytes == null || bytes.isEmpty || !content.mimeType.startsWith('image/')) {
      setState(() => _status = 'Rich content was received, but no image bytes were available.');
      return;
    }
    setState(() {
      _imageBytes = bytes;
      _imageMimeType = content.mimeType;
      _status = 'Attached ${content.mimeType} from rich content insertion (${bytes.length} bytes).';
    });
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
    final preview = _buildPrompt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepCard(
          number: 1,
          title: 'Paste the source',
          subtitle: 'Start from what you already have instead of filling fields in an arbitrary UI order.',
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
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Raw text / rough request / existing prompt',
                  hintText: 'Paste notes, an existing prompt, requirements, or conversation excerpts here.',
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
                    label: const Text('Paste text'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      _rawController.clear();
                      setState(() => _status = 'Cleared the raw source.');
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _StepCard(
          number: 2,
          title: 'Add visual context',
          subtitle: 'Images are useful for “make the UI more like this” requests; video stays optional and out of this first clipboard flow.',
          child: _ImageReferenceCard(
            bytes: _imageBytes,
            mimeType: _imageMimeType,
            onRemove: _imageBytes == null
                ? null
                : () => setState(() {
                      _imageBytes = null;
                      _imageMimeType = null;
                      _status = 'Removed the visual reference.';
                    }),
          ),
        ),
        const SizedBox(height: 12),
        _StepCard(
          number: 3,
          title: 'Shape the instruction',
          subtitle: 'Organize the request in the order a person typically decides it: goal → context → must-have → constraints → output.',
          child: Column(
            children: [
              _Field(controller: _goalController, label: 'Goal', hint: 'What should the assistant/system accomplish?', onChanged: () => setState(() {})),
              _Field(controller: _contextController, label: 'Context', hint: 'Background, target users, project facts, existing behavior.', onChanged: () => setState(() {})),
              _Field(controller: _requirementsController, label: 'Must include', hint: 'Required behavior, screens, APIs, acceptance criteria.', onChanged: () => setState(() {})),
              _Field(controller: _constraintsController, label: 'Constraints / avoid', hint: 'Dependencies to avoid, compatibility rules, non-goals.', onChanged: () => setState(() {})),
              _Field(controller: _outputController, label: 'Output format', hint: 'PR, patch, Markdown, JSON, implementation plan, etc.', onChanged: () => setState(() {})),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _StepCard(
          number: 4,
          title: 'Preview and copy',
          subtitle: 'The generated text is intentionally plain Markdown so it can be pasted into ChatGPT, Claude, an Issue, or another tool.',
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
                label: const Text('Copy system prompt'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Semantics(liveRegion: true, child: Text(_status, style: Theme.of(context).textTheme.bodySmall)),
      ],
    );
  }
}

class _ImageReferenceCard extends StatelessWidget {
  const _ImageReferenceCard({required this.bytes, required this.mimeType, required this.onRemove});

  final Uint8List? bytes;
  final String? mimeType;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    if (bytes == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.image_outlined),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Image insertion is wired through Flutter rich-content insertion where the platform supplies image bytes. Plain clipboard buttons use Flutter’s text clipboard API, so unsupported platforms keep this area empty without adding a heavy clipboard plugin.',
              ),
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
          child: Image.memory(bytes!, height: 220, width: double.infinity, fit: BoxFit.contain),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: Text('${mimeType ?? 'image'} · ${bytes!.length} bytes')),
            TextButton.icon(onPressed: onRemove, icon: const Icon(Icons.delete_outline), label: const Text('Remove')),
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
