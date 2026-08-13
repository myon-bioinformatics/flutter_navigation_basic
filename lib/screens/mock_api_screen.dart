import 'package:flutter/material.dart';
import '../data/mock_api_client.dart';

class MockApiScreen extends StatefulWidget {
  const MockApiScreen({super.key});

  @override
  State<MockApiScreen> createState() => _MockApiScreenState();
}

class _MockApiScreenState extends State<MockApiScreen> {
  final MockApiClient _client = MockApiClient();
  bool _loading = false;
  String _result = 'Choose an endpoint to call.';

  Future<void> _run(
    Future<dynamic> Function() request,
    String label,
  ) async {
    setState(() {
      _loading = true;
      _result = 'Calling $label…';
    });

    try {
      final response = await request();
      if (!mounted) return;

      setState(() {
        _result = 'HTTP ${response.statusCode}\n${response.body}';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _result = 'Request failed\n$error';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mock API Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Base URL',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          SelectableText(MockApiClient.defaultBaseUrl),
          const SizedBox(height: 16),
          const Text(
            'For GitHub Pages, build with '
            '--dart-define=MOCK_API_BASE_URL=https://your-mock-host.example. '
            'The default localhost URL is intended for local Docker testing.',
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _loading
                ? null
                : () => _run(_client.fetchHealth, 'GET /api/health'),
            icon: const Icon(Icons.monitor_heart_outlined),
            label: const Text('GET /api/health'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loading
                ? null
                : () => _run(_client.fetchUser1, 'GET /api/users/1'),
            icon: const Icon(Icons.person_outline),
            label: const Text('GET /api/users/1'),
          ),
          const SizedBox(height: 24),
          if (_loading) const LinearProgressIndicator(),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText(_result),
            ),
          ),
        ],
      ),
    );
  }
}
