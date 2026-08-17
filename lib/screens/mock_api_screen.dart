import 'dart:convert';

import 'package:flutter/material.dart';
import '../data/mock_api_client.dart';
import '../shared/display/display_scope.dart';

class ApiIntegrationScreen extends StatefulWidget {
  const ApiIntegrationScreen({super.key});

  @override
  State<ApiIntegrationScreen> createState() => _ApiIntegrationScreenState();
}

class _ApiIntegrationScreenState extends State<ApiIntegrationScreen> {
  final MockApiClient _client = MockApiClient();
  bool _loading = false;
  String? _result;

  Future<void> _run(String scenario) async {
    setState(() { _loading = true; _result = 'Loading $scenario…'; });
    try {
      final data = await _client.fetchScenario('api', scenario);
      if (!mounted) return;
      final status = data['simulatedStatus'];
      final request = data['request'];
      final response = const JsonEncoder.withIndent('  ').convert(data['response']);
      setState(() => _result = '$request\nSimulated HTTP $status\n\n$response');
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
      ('get', 'GET', Icons.download_outlined),
      ('post', 'POST', Icons.upload_outlined),
      ('timeout', 'Timeout', Icons.timer_outlined),
      ('unauthorized', '401', Icons.lock_outline),
      ('serverError', '500', Icons.error_outline),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(display.text('home.api')), backgroundColor: Theme.of(context).colorScheme.inversePrimary, actions: const [DisplayLocalePicker(compact: true)]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(display.text('home.api'), style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(display.text('home.apiSubtitle')),
        const SizedBox(height: 12),
        SelectableText('Mock: ${MockApiClient.defaultBaseUrl}'),
        const SizedBox(height: 20),
        Wrap(spacing: 10, runSpacing: 10, children: [for (final item in scenarios) FilledButton.tonalIcon(onPressed: _loading ? null : () => _run(item.$1), icon: Icon(item.$3), label: Text(item.$2))]),
        const SizedBox(height: 24),
        if (_loading) const LinearProgressIndicator(),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: SelectableText(_result ?? display.text('home.apiSubtitle')))),
      ]),
    );
  }
}
