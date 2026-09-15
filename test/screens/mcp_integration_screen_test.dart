import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/screens/mcp_integration_screen.dart';
import 'package:flutter_application_1/shared/display/display_scope.dart';

import '../support/display_test_harness.dart';

Future<void> _pumpMcpScreen(
  WidgetTester tester, {
  required DisplayController controller,
}) async {
  // Foundation + dual-era sections push the result card below the default
  // 600px test viewport; ListView only builds visible children.
  await tester.binding.setSurfaceSize(const Size(390, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      home: DisplayScope(controller: controller, child: const McpIntegrationScreen()),
    ),
  );
}

void main() {
  // Scenario buttons trigger a real network fetch via MockApiClient, which has
  // no fixture/mock in this suite and would hang or fail in a sandboxed CI
  // environment without egress. These tests only cover the static catalog
  // chrome rendered before any scenario is run.
  testWidgets('renders catalog chrome for the default (no scenario run) state', (tester) async {
    final controller = await loadTestDisplayController();
    await _pumpMcpScreen(tester, controller: controller);

    expect(find.text('External Integration · MCP'), findsOneWidget);
    expect(find.text('MCP Demo'), findsOneWidget);
    expect(find.text('Choose an MCP scenario.'), findsOneWidget);
    expect(find.text('tool list'), findsOneWidget);
    expect(find.text('tool call'), findsOneWidget);
    expect(find.textContaining('Mock: '), findsOneWidget);
    expect(find.textContaining('Foundation session'), findsOneWidget);
    expect(find.textContaining('dual-era MCP support'), findsOneWidget);
  });

  testWidgets('renders translated chrome for a non-English display locale', (tester) async {
    final controller = await loadTestDisplayController(
      initialValues: {DisplayController.preferenceKey: 'jpn'},
    );
    await _pumpMcpScreen(tester, controller: controller);

    expect(find.text('MCPデモ'), findsOneWidget);
    expect(find.text('MCPシナリオを選択してください。'), findsOneWidget);
    expect(find.text('ツール一覧'), findsOneWidget);
  });
}
