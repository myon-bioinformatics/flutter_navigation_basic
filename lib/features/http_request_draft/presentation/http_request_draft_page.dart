import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/navigation/route_names.dart';
import '../../../core/utils/ascii_fullwidth.dart';
import '../../../shared/display/display_scope.dart';
import '../../../shared/http/auth_matrix.dart';
import '../../../shared/http/curl_safe_subset.dart';
import '../../../shared/http/live_request_executor.dart';
import '../../../shared/http/mock_auth.dart';
import '../../../shared/http/request_draft.dart';
import '../../../shared/http/request_draft_codec.dart';
import '../../../shared/http/request_executor.dart';
import '../../../shared/http/request_field.dart';
import '../../../shared/input/ascii_fullwidth_text_input_formatter.dart';
import '../../../shared/widgets/tool_door_selector.dart';

/// HTTP request draft editor: edit fields, apply auth presets, execute mock
/// (and live IO where supported), and copy redacted receipts/curl.
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
  late final TextEditingController _curlImport;
  RequestDraft _draft = RequestDraft.empty().copyWith(
    query: [RequestField(id: _nextId())],
    headers: [RequestField(id: _nextId())],
    formFields: [RequestField(id: _nextId())],
  );

  final _queryControllers = <String, _FieldControllers>{};
  final _headerControllers = <String, _FieldControllers>{};
  final _formControllers = <String, _FieldControllers>{};
  List<RequestDraftIssue> _importErrors = const [];
  List<RequestDraftIssue> _importWarnings = const [];
  AuthMatrixScenario _authScenario = AuthMatrixScenario.none;
  bool _executing = false;
  String _receipt = '';
  late final MockAuthRequestExecutor _mockExecutor;


  @override
  void initState() {
    super.initState();
    _url = TextEditingController(text: _draft.url);
    _rawBody = TextEditingController(text: _draft.rawBody);
    _curlImport = TextEditingController();
    _syncFieldControllers();
    final auth = MockAuthHandler();
    _mockExecutor = MockAuthRequestExecutor(
      handler: ({
        required method,
        required path,
        required headers,
        required query,
        required queryPairs,
        requestTarget,
        body,
      }) {
        final result = auth.handle(
          method: method,
          path: path,
          headers: headers,
          query: query,
          requestTarget: requestTarget,
          body: body,
          queryPairs: queryPairs,
        );
        if (result == null) return null;
        return (
          statusCode: result.statusCode,
          body: result.body,
          headers: result.headers,
        );
      },
      hmacSecret: MockAuthDemo.hmacSecret,
      hmacKeyId: MockAuthDemo.hmacKeyId,
      digestUsername: MockAuthDemo.basicUser,
      digestPassword: MockAuthDemo.basicPassword,
    );
  }

  @override
  void dispose() {
    _url.dispose();
    _rawBody.dispose();
    _curlImport.dispose();
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

  void _setDraft(RequestDraft draft, {bool syncTopLevelControllers = false}) {
    setState(() {
      _draft = draft;
      _syncFieldControllers();
      if (syncTopLevelControllers) {
        _url.text = draft.url;
        _rawBody.text = draft.rawBody;
      }
    });
  }

  void _clearDraft() {
    _url.clear();
    _rawBody.clear();
    _importErrors = const [];
    _importWarnings = const [];
    _setDraft(
      RequestDraft.empty().copyWith(
        query: [RequestField(id: _nextId())],
        headers: [RequestField(id: _nextId())],
        formFields: [RequestField(id: _nextId())],
      ),
    );
  }

  void _importCurl() {
    final result = CurlSafeSubset.tryParse(
      _curlImport.text,
      newId: _nextId,
    );
    setState(() {
      _importErrors = result.errors;
      _importWarnings = result.warnings;
    });
    if (result.draft == null) return;
    _setDraft(result.draft!, syncTopLevelControllers: true);
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


  void _applyAuthScenario(AuthMatrixScenario scenario) {
    final next = scenario.applyTo(
      _draft,
      baseUrl: 'http://127.0.0.1:8787',
    );
    setState(() {
      _authScenario = scenario;
      _draft = next;
      _receipt = '';
      _syncFieldControllers();
      _url.text = next.url;
      _rawBody.text = next.rawBody;
    });
  }

  Future<void> _executeMock() async {
    if (_executing) return;
    final issues = RequestDraftValidator.validate(_draft);
    if (issues.isNotEmpty) {
      setState(() {
        _receipt = 'validation_failed: ${[for (final i in issues) i.code].join(', ')}';
      });
      return;
    }
    setState(() {
      _executing = true;
      _receipt = '';
    });
    try {
      final scenario =
          _authScenario == AuthMatrixScenario.none ? null : _authScenario;
      final result = _mockExecutor.execute(_draft, scenario: scenario);
      final wire = result.wireDraft ?? _draft;
      final redactedCurl =
          RequestDraftCodec.toCurl(wire, redactSecrets: true);
      final receipt = formatExecutionReceipt(
        draft: wire,
        result: result,
        redactedCurl: redactedCurl,
      );
      if (!mounted) return;
      setState(() => _receipt = receipt);
    } finally {
      if (mounted) setState(() => _executing = false);
    }
  }

  Future<void> _executeLive() async {
    if (_executing) return;
    final issues = RequestDraftValidator.validate(_draft);
    if (issues.isNotEmpty) {
      setState(() {
        _receipt = 'validation_failed: ${[for (final i in issues) i.code].join(', ')}';
      });
      return;
    }
    setState(() {
      _executing = true;
      _receipt = '';
    });
    try {
      final scenario =
          _authScenario == AuthMatrixScenario.none ? null : _authScenario;
      final result = await _mockExecutor.executePrepared(
        _draft,
        scenario: scenario,
        dispatch: executeLiveRequest,
        basePath: 'live',
      );
      final wire = result.wireDraft ?? _draft;
      final redactedCurl =
          RequestDraftCodec.toCurl(wire, redactSecrets: true);
      final receipt = formatExecutionReceipt(
        draft: wire,
        result: result,
        redactedCurl: redactedCurl,
      );
      if (!mounted) return;
      final display = DisplayScope.of(context);
      final limitation = display.text(liveHttpCapabilities.limitationKey);
      setState(() => _receipt = '$limitation\n\n$receipt');
    } finally {
      if (mounted) setState(() => _executing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
        final issues = RequestDraftValidator.validate(_draft);
    final previewScenario =
        _authScenario == AuthMatrixScenario.none ? null : _authScenario;
    final previewWire = _mockExecutor
        .prepareWireDraft(_draft, scenario: previewScenario)
        .draft;
    final redactedCurl =
        CurlSafeSubset.export(previewWire, redactSecrets: true);
    final uri = RequestDraftCodec.buildUri(previewWire, redactSecrets: true);
    final headers =
        RequestDraftCodec.buildHeaders(previewWire, redactSecrets: true);
    final body = RequestDraftCodec.buildBody(previewWire, redactSecrets: true);

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
          _sectionTitle(display.text('httpDraft.curlImport')),
          TextField(
            controller: _curlImport,
            minLines: 3,
            maxLines: 8,
            inputFormatters: asciiFullwidthInputFormatters,
            style: const TextStyle(
              fontFamily: 'monospace',
              letterSpacing: 0,
              fontSize: 12,
            ),
            decoration: InputDecoration(
              labelText: display.text('httpDraft.curlImportHint'),
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: _importCurl,
              icon: const Icon(Icons.upload_file_outlined),
              label: Text(display.text('httpDraft.importCurl')),
            ),
          ),
          if (_importErrors.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final issue in _importErrors)
              Text(
                '• ${display.text(issue.code, arguments: {
                      if (issue.argument != null) 'name': issue.argument!,
                      if (issue.argument != null) 'flag': issue.argument!,
                    })}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
          if (_importWarnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final issue in _importWarnings)
              Text(
                '• ${display.text(issue.code, arguments: {
                      if (issue.argument != null) 'name': issue.argument!,
                      if (issue.argument != null) 'flag': issue.argument!,
                    })}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
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
            showSensitive: true,
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
              _draft.bodyMode == RequestBodyMode.json) ...[
            Text(
              display.text('httpDraft.bodySecretDisclaimer'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
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
          ],
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

          const SizedBox(height: 20),
          _sectionTitle(display.text('httpDraft.executeSection')),
          Text(
            display.text(liveHttpCapabilities.limitationKey),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          InputDecorator(
            decoration: InputDecoration(
              labelText: display.text('httpDraft.authPreset'),
              border: const OutlineInputBorder(),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<AuthMatrixScenario>(
                isExpanded: true,
                value: _authScenario,
                items: [
                  for (final scenario in AuthMatrixScenario.values)
                    DropdownMenuItem(
                      value: scenario,
                      child: Text(display.text(scenario.labelKey)),
                    ),
                ],
                onChanged: _executing
                    ? null
                    : (scenario) {
                        if (scenario == null) return;
                        _applyAuthScenario(scenario);
                      },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _executing ? null : _executeMock,
                icon: const Icon(Icons.play_arrow),
                label: Text(display.text('httpDraft.executeMock')),
              ),
              FilledButton.tonalIcon(
                onPressed: _executing ? null : _executeLive,
                icon: const Icon(Icons.cloud_outlined),
                label: Text(display.text('httpDraft.executeLive')),
              ),
              if (_receipt.isNotEmpty)
                FilledButton.tonalIcon(
                  onPressed: () => _copy(
                    _receipt,
                    display.text('httpDraft.receipt'),
                  ),
                  icon: const Icon(Icons.copy_all),
                  label: Text(display.text('httpDraft.copyReceipt')),
                ),
            ],
          ),
          if (_executing) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ],
          if (_receipt.isNotEmpty) ...[
            const SizedBox(height: 12),
            _sectionTitle(display.text('httpDraft.receipt')),
            SelectableText(
              _receipt,
              style: const TextStyle(
                fontFamily: 'monospace',
                letterSpacing: 0,
                fontSize: 12,
              ),
            ),
          ],
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
