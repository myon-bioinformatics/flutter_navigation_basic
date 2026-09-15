import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/mock_api_client.dart';
import '../shared/display/display_scope.dart';
import '../shared/mcp/mcp.dart';

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
  String _foundationLog = '';

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


  Future<void> _runFoundationEcho() async {
    final display = DisplayScope.of(context);
    setState(() {
      _loading = true;
      _foundationLog = display.text('mcp.foundationRunning');
    });
    try {
      final client = McpSessionClient(
        transport: FoundationHandlerTransport(McpFoundationHandler()),
      );
      final result = await client.runEchoDemo(text: 'hello-from-ui');
      if (!mounted) return;
      final display2 = DisplayScope.of(context);
      setState(() {
        _foundationLog = [
          display2.text(
            'mcp.support.pinned',
            arguments: {'version': McpProtocol.specificationVersion},
          ),
          display2.text(
            'mcp.support.currentOfficial',
            arguments: {'version': McpProtocol.currentOfficialVersion},
          ),
          display2.text(
            'mcp.support.implementsCurrent',
            arguments: {
              'value': '${McpProtocol.implementsCurrentOfficial}',
            },
          ),
          display2.text(
            'mcp.support.okSession',
            arguments: {
              'ok': '${result.ok}',
              'session': '${result.sessionId}',
            },
          ),
          ...result.log,
        ].join('\n');
      });
    } catch (error) {
      if (!mounted) return;
      final display2 = DisplayScope.of(context);
      setState(() {
        _foundationLog = display2.text(
          'mcp.foundationFailed',
          arguments: {'error': '$error'},
        );
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _runModernEcho() async {
    final display = DisplayScope.of(context);
    setState(() {
      _loading = true;
      _foundationLog = display.text('mcp.era.modernRunning');
    });
    try {
      final client = McpSessionClient(
        transport: FoundationHandlerTransport(McpFoundationHandler()),
      );
      final result = await client.runModernEchoDemo(text: 'hello-modern');
      if (!mounted) return;
      final display2 = DisplayScope.of(context);
      setState(() {
        _foundationLog = [
          display2.text('mcp.era.dualSupported'),
          display2.text(
            'mcp.support.currentOfficial',
            arguments: {'version': McpProtocol.currentOfficialVersion},
          ),
          display2.text(
            'mcp.support.okSession',
            arguments: {
              'ok': '${result.ok}',
              'session': '${result.sessionId ?? '-'}',
            },
          ),
          ...result.log,
        ].join('\n');
      });
    } catch (error) {
      if (!mounted) return;
      final display2 = DisplayScope.of(context);
      setState(() {
        _foundationLog = display2.text(
          'mcp.foundationFailed',
          arguments: {'error': '$error'},
        );
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
          const SizedBox(height: 16),
          Text(
            display.text('mcp.foundationSection', arguments: {'version': McpProtocol.specificationVersion}),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _loading ? null : _runFoundationEcho,
            icon: const Icon(Icons.hub_outlined),
            label: Text(display.text('mcp.foundationRunEcho')),
          ),
          const SizedBox(height: 8),
          Text(
            display.text(
              'mcp.era.modernSection',
              arguments: {'version': McpProtocol.currentOfficialVersion},
            ),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(display.text('mcp.era.dualSupported')),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: _loading ? null : _runModernEcho,
            icon: const Icon(Icons.auto_awesome_outlined),
            label: Text(display.text('mcp.era.modernRun')),
          ),
          if (_foundationLog.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(_foundationLog),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            display.text('mcp.legacyScenariosSection'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
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
