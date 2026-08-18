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
  String _resultKey = 'mcp.chooseScenario';
  Map<String, Object?> _resultArgs = const {};

  Future<void> _run(String scenario) async {
    setState(() {
      _loading = true;
      _resultKey = 'common.loadingScenario';
      _resultArgs = {'scenario': scenario};
    });

    try {
      final data = await _client.fetchScenario('mcp', scenario);
      if (!mounted) return;
      final display = DisplayScope.of(context);

      final status = data['simulatedStatus'];
      final request = data['request'];
      final requestBody = data['requestBody'];
      final response = const JsonEncoder.withIndent('  ').convert(data['response']);
      final requestBodyText = requestBody == null
          ? ''
          : display.text('mcp.requestBodyText', arguments: {
              'body': const JsonEncoder.withIndent('  ').convert(requestBody),
            });

      setState(() {
        _resultKey = 'mcp.result';
        _resultArgs = {
          'request': request,
          'status': status,
          'requestBodyText': requestBodyText,
          'response': response,
        };
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _resultKey = 'common.requestFailed';
        _resultArgs = {'error': error};
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    final scenarios = <(String, String, IconData)>[
      ('toolList', display.text('mcp.scenarioToolList'), Icons.list_alt_outlined),
      ('toolCall', display.text('mcp.scenarioToolCall'), Icons.play_arrow_outlined),
      ('success', display.text('mcp.scenarioSuccess'), Icons.check_circle_outline),
      ('malformedArguments', display.text('mcp.scenarioMalformed'), Icons.data_object_outlined),
      ('toolError', display.text('mcp.scenarioError'), Icons.warning_amber_outlined),
    ];
    final result = display.text(_resultKey, arguments: _resultArgs);

    return Scaffold(
      appBar: AppBar(
        title: Text(display.text('mcp.title')),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(display.text('mcp.headline'), style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(display.text('mcp.description')),
          const SizedBox(height: 12),
          SelectableText(display.text('common.mockLabel', arguments: {'url': MockApiClient.defaultBaseUrl})),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final item in scenarios)
                FilledButton.tonalIcon(
                  onPressed: _loading ? null : () => _run(item.$1),
                  icon: Icon(item.$3),
                  label: Text(item.$2),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (_loading) const LinearProgressIndicator(),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText(result),
            ),
          ),
        ],
      ),
    );
  }
}
