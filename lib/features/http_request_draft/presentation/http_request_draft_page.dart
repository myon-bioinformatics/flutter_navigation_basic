import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/navigation/route_names.dart';
import '../../../core/utils/ascii_fullwidth.dart';
import '../../../shared/display/display_scope.dart';
import '../../../shared/http/request_draft.dart';
import '../../../shared/http/request_draft_codec.dart';
import '../../../shared/http/request_field.dart';
import '../../../shared/input/ascii_fullwidth_text_input_formatter.dart';
import '../../../shared/widgets/tool_door_selector.dart';

/// Offline HTTP request draft editor (no network). Previews + redacted curl.
class HttpRequestDraftPage extends StatefulWidget {
  const HttpRequestDraftPage({super.key});

  @override
  State<HttpRequestDraftPage> createState() => _HttpRequestDraftPageState();
}

class _HttpRequestDraftPageState extends State<HttpRequestDraftPage> {
  static var _seq = 0;
  static String _nextId() => 'f${_seq++}';

  late final TextEditingController _url;
  late final TextEditingController _rawBody;
  RequestDraft _draft = RequestDraft.empty().copyWith(
    query: [RequestField(id: _nextId())],
    headers: [RequestField(id: _nextId())],
    formFields: [RequestField(id: _nextId())],
  );

  final _queryControllers = <String, _FieldControllers>{};
  final _headerControllers = <String, _FieldControllers>{};
  final _formControllers = <String, _FieldControllers>{};

  @override
  void initState() {
    super.initState();
    _url = TextEditingController(text: _draft.url);
    _rawBody = TextEditingController(text: _draft.rawBody);
    _syncFieldControllers();
  }

  @override
  void dispose() {
    _url.dispose();
    _rawBody.dispose();
    for (final c in _queryControllers.values) {
      c.dispose();
    }
    _queryControllers.clear();
    for (final c in _headerControllers.values) {
      c.dispose();
    }
    _headerControllers.clear();
    for (final c in _formControllers.values) {
      c.dispose();
    }
    _formControllers.clear();
    super.dispose();
  }

  void _syncFieldControllers() {
    void sync(
      List<RequestField> fields,
      Map<String, _FieldControllers> map,
    ) {
      final keep = fields.map((f) => f.id).toSet();
      for (final id in map.keys.toList()) {
        if (!keep.contains(id)) {
          map.remove(id)?.dispose();
        }
      }
      for (final field in fields) {
        map.putIfAbsent(
          field.id,
          () => _FieldControllers(
            name: TextEditingController(text: field.name),
            value: TextEditingController(text: field.value),
          ),
        );
      }
    }

    sync(_draft.query, _queryControllers);
    sync(_draft.headers, _headerControllers);
    sync(_draft.formFields, _formControllers);
  }

  void _setDraft(RequestDraft draft) {
    setState(() {
      _draft = draft;
      _syncFieldControllers();
    });
  }

  void _clearDraft() {
    _url.clear();
    _rawBody.clear();
    _setDraft(
      RequestDraft.empty().copyWith(
        query: [RequestField(id: _nextId())],
        headers: [RequestField(id: _nextId())],
        formFields: [RequestField(id: _nextId())],
      ),
    );
  }

  Future<void> _copy(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    final display = DisplayScope.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          display.text('httpDraft.copied', arguments: {'label': label}),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    final issues = RequestDraftValidator.validate(_draft);
    final redactedCurl =
        RequestDraftCodec.toCurl(_draft, redactSecrets: true);
    final uri = RequestDraftCodec.buildUri(_draft);
    final headers =
        RequestDraftCodec.buildHeaders(_draft, redactSecrets: true);
    final body = RequestDraftCodec.buildBody(_draft, redactSecrets: true);

    return Scaffold(
      appBar: AppBar(
        title: Text(display.text('httpDraft.title')),
        actions: [
          TextButton(
            onPressed: _clearDraft,
            child: Text(display.text('httpDraft.clear')),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            display.text('httpDraft.subtitle'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              DropdownButton<HttpMethod>(
                value: _draft.method,
                items: [
                  for (final method in HttpMethod.values)
                    DropdownMenuItem(
                      value: method,
                      child: Text(method.label),
                    ),
                ],
                onChanged: (method) {
                  if (method == null) return;
                  _setDraft(_draft.copyWith(method: method));
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _url,
                  inputFormatters: asciiFullwidthInputFormatters,
                  style: const TextStyle(letterSpacing: 0),
                  decoration: InputDecoration(
                    labelText: display.text('httpDraft.url'),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) =>
                      _setDraft(_draft.copyWith(url: value)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionTitle(display.text('httpDraft.query')),
          _fieldEditor(
            fields: _draft.query,
            controllers: _queryControllers,
            onChanged: (next) => _setDraft(_draft.copyWith(query: next)),
            showSensitive: false,
          ),
          const SizedBox(height: 16),
          _sectionTitle(display.text('httpDraft.headers')),
          _fieldEditor(
            fields: _draft.headers,
            controllers: _headerControllers,
            onChanged: (next) => _setDraft(_draft.copyWith(headers: next)),
            showSensitive: true,
            namePresets: const [
              'Authorization',
              'X-API-Key',
              'Content-Type',
              'Accept',
              'Cookie',
            ],
          ),
          const SizedBox(height: 16),
          _sectionTitle(display.text('httpDraft.body')),
          Wrap(
            spacing: 8,
            children: [
              for (final mode in RequestBodyMode.values)
                ChoiceChip(
                  label: Text(_bodyModeLabel(display, mode)),
                  selected: _draft.bodyMode == mode,
                  onSelected: (_) =>
                      _setDraft(_draft.copyWith(bodyMode: mode)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_draft.bodyMode == RequestBodyMode.raw ||
              _draft.bodyMode == RequestBodyMode.json)
            TextField(
              controller: _rawBody,
              minLines: 4,
              maxLines: 10,
              inputFormatters: asciiFullwidthInputFormatters,
              style: const TextStyle(letterSpacing: 0),
              decoration: InputDecoration(
                labelText: _draft.bodyMode == RequestBodyMode.json
                    ? display.text('httpDraft.jsonBody')
                    : display.text('httpDraft.rawBody'),
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              onChanged: (value) =>
                  _setDraft(_draft.copyWith(rawBody: value)),
            ),
          if (_draft.bodyMode == RequestBodyMode.formUrlEncoded ||
              _draft.bodyMode == RequestBodyMode.multipart)
            _fieldEditor(
              fields: _draft.formFields,
              controllers: _formControllers,
              onChanged: (next) =>
                  _setDraft(_draft.copyWith(formFields: next)),
              showSensitive: true,
            ),
          const SizedBox(height: 20),
          if (issues.isNotEmpty) ...[
            Text(
              display.text('httpDraft.issues'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (final issue in issues)
              Text(
                '• ${display.text(issue.code, arguments: {
                      if (issue.argument != null) 'name': issue.argument!,
                    })}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 12),
          ],
          _sectionTitle(display.text('httpDraft.preview')),
          SelectableText(
            '${_draft.method.label} ${uri ?? _draft.normalizedUrl}',
            style: const TextStyle(letterSpacing: 0),
          ),
          const SizedBox(height: 8),
          for (final entry in headers.entries)
            Text(
              '${entry.key}: ${entry.value}',
              style: const TextStyle(letterSpacing: 0),
            ),
          if (body != null && body.isNotEmpty) ...[
            const SizedBox(height: 8),
            SelectableText(body, style: const TextStyle(letterSpacing: 0)),
          ],
          const SizedBox(height: 16),
          _sectionTitle(display.text('httpDraft.curlRedacted')),
          SelectableText(
            redactedCurl,
            style: const TextStyle(
              fontFamily: 'monospace',
              letterSpacing: 0,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: () => _copy(
                redactedCurl,
                display.text('httpDraft.curlRedacted'),
              ),
              icon: const Icon(Icons.copy),
              label: Text(display.text('httpDraft.copyCurl')),
            ),
          ),
          const SizedBox(height: 24),
          const ToolDoorSelector(
            currentRouteName: RouteNames.httpRequestDraft,
          ),
        ],
      ),
    );
  }

  String _bodyModeLabel(DisplayController display, RequestBodyMode mode) {
    return switch (mode) {
      RequestBodyMode.none => display.text('httpDraft.bodyNone'),
      RequestBodyMode.raw => display.text('httpDraft.bodyRaw'),
      RequestBodyMode.json => display.text('httpDraft.bodyJson'),
      RequestBodyMode.formUrlEncoded => display.text('httpDraft.bodyForm'),
      RequestBodyMode.multipart => display.text('httpDraft.bodyMultipart'),
    };
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );

  Widget _fieldEditor({
    required List<RequestField> fields,
    required Map<String, _FieldControllers> controllers,
    required ValueChanged<List<RequestField>> onChanged,
    required bool showSensitive,
    List<String> namePresets = const [],
  }) {
    final display = DisplayScope.of(context);
    return Column(
      children: [
        for (var i = 0; i < fields.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: fields[i].enabled,
                  onChanged: (v) {
                    final next = [...fields];
                    next[i] = next[i].copyWith(enabled: v ?? true);
                    onChanged(next);
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: controllers[fields[i].id]!.name,
                    inputFormatters: asciiFullwidthInputFormatters,
                    style: const TextStyle(letterSpacing: 0),
                    decoration: InputDecoration(
                      labelText: display.text('httpDraft.fieldName'),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      final next = [...fields];
                      next[i] = next[i].copyWith(name: value);
                      onChanged(next);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controllers[fields[i].id]!.value,
                    inputFormatters: asciiFullwidthInputFormatters,
                    style: const TextStyle(letterSpacing: 0),
                    obscureText: showSensitive && fields[i].sensitive,
                    decoration: InputDecoration(
                      labelText: display.text('httpDraft.fieldValue'),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      final next = [...fields];
                      next[i] = next[i].copyWith(value: value);
                      onChanged(next);
                    },
                  ),
                ),
                if (showSensitive)
                  IconButton(
                    tooltip: display.text('httpDraft.sensitive'),
                    onPressed: () {
                      final next = [...fields];
                      next[i] =
                          next[i].copyWith(sensitive: !next[i].sensitive);
                      onChanged(next);
                    },
                    icon: Icon(
                      fields[i].sensitive
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                IconButton(
                  tooltip: display.text('httpDraft.deleteRow'),
                  onPressed: fields.length <= 1
                      ? null
                      : () {
                          final next = [...fields]..removeAt(i);
                          onChanged(next);
                        },
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        if (namePresets.isNotEmpty)
          Wrap(
            spacing: 6,
            children: [
              for (final preset in namePresets)
                ActionChip(
                  label: Text(preset),
                  onPressed: () {
                    final emptyIndex = fields.indexWhere(
                      (f) => normalizeAsciiFullwidth(f.name).trim().isEmpty,
                    );
                    final next = [...fields];
                    if (emptyIndex >= 0) {
                      next[emptyIndex] =
                          next[emptyIndex].copyWith(name: preset);
                      controllers[next[emptyIndex].id]!.name.text = preset;
                    } else {
                      next.add(RequestField(id: _nextId(), name: preset));
                    }
                    onChanged(next);
                  },
                ),
            ],
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              onChanged([...fields, RequestField(id: _nextId())]);
            },
            icon: const Icon(Icons.add),
            label: Text(display.text('httpDraft.addRow')),
          ),
        ),
      ],
    );
  }
}

class _FieldControllers {
  _FieldControllers({required this.name, required this.value});

  final TextEditingController name;
  final TextEditingController value;

  void dispose() {
    name.dispose();
    value.dispose();
  }
}
