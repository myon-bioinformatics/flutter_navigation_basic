import 'dart:convert';

import 'package:flutter/material.dart';
import '../data/mock_api_client.dart';
import '../shared/display/display_scope.dart';

class McpIntegrationScreen extends StatefulWidget {
  const McpIntegrationScreen({super.key});

  @override
  State<McpIntegrationScreen> createState() => _McpIntegrationScreenState();
}

class _McpIntegrationScreenState extends State<McpIntegrationScreen> {
  final MockApiClient _client = MockApiClient();
  bool _loading = false;
  String? _result;

  Future<void> _run(String scenario) async {
    setState(() { _loading = true; _result = 'Loading $scenario…'; });
    try {
      final data = await _client.fetchScenario('mcp', scenario);
      if (!mounted) return;
      final status = data['simulatedStatus'];
      final request = data['request'];
      final requestBody = data['requestBody'];
      final response = const JsonEncoder.withIndent('  ').convert(data['response']);
      final requestText = requestBody == null ? '' : '\nRequest body:\n${const JsonEncoder.withIndent('  ').convert(requestBody)}';
      setState(() => _result = '$request\nSimulated HTTP $status$requestText\n\nResponse:\n$response');
    } catch (error) {
      if (!mounted) return;
      setState(() => _result = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    const scenarios = <(String, String, IconData)>[
      ('toolList', 'tool list', Icons.list_alt_outlined),
      ('toolCall', 'tool call', Icons.play_arrow_outlined),
      ('success', 'success result', Icons.check_circle_outline),
      ('malformedArguments', 'malformed arguments', Icons.data_object_outlined),
      ('toolError', 'tool error', Icons.warning_amber_outlined),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(display.text('home.mcp')), backgroundColor: Theme.of(context).colorScheme.inversePrimary, actions: const [DisplayLocalePicker(compact: true)]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(display.text('home.mcp'), style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(display.text('home.mcpSubtitle')),
        const SizedBox(height: 12),
        SelectableText('Mock: ${MockApiClient.defaultBaseUrl}'),
        const SizedBox(height: 20),
        Wrap(spacing: 10, runSpacing: 10, children: [for (final item in scenarios) FilledButton.tonalIcon(onPressed: _loading ? null : () => _run(item.$1), icon: Icon(item.$3), label: Text(item.$2))]),
        const SizedBox(height: 24),
        if (_loading) const LinearProgressIndicator(),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: SelectableText(_result ?? display.text('home.mcpSubtitle')))),
      ]),
    );
  }
}
