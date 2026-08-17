import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/display/display_scope.dart';
import '../domain/coordinate_formatter.dart';

class CoordinateToolPage extends StatefulWidget {
  const CoordinateToolPage({super.key});

  @override
  State<CoordinateToolPage> createState() => _CoordinateToolPageState();
}

class _CoordinateToolPageState extends State<CoordinateToolPage> {
  final _latitude = TextEditingController(text: '35.681236');
  final _longitude = TextEditingController(text: '139.767125');
  CoordinateValue? _value;
  String? _error;

  @override
  void initState() { super.initState(); _convert(); }

  @override
  void dispose() { _latitude.dispose(); _longitude.dispose(); super.dispose(); }

  void _convert() {
    try {
      final value = CoordinateValue.parse(latitude: _latitude.text, longitude: _longitude.text);
      setState(() { _value = value; _error = null; });
    } on FormatException catch (error) {
      setState(() { _value = null; _error = error.message.toString(); });
    }
  }

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(DisplayScope.of(context).text('coordinate.copyDone'))));
  }

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    String t(String key) => display.text(key);
    final value = _value;
    return Scaffold(
      appBar: AppBar(title: Text(t('coordinate.title')), actions: const [DisplayLocalePicker(compact: true)]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 72),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(t('coordinate.subtitle'), style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 20),
              TextField(controller: _latitude, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: InputDecoration(labelText: t('coordinate.latitude'), helperText: '-90 to 90', border: const OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _longitude, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: InputDecoration(labelText: t('coordinate.longitude'), helperText: '-180 to 180', border: const OutlineInputBorder())),
              const SizedBox(height: 16),
              FilledButton.icon(onPressed: _convert, icon: const Icon(Icons.swap_horiz), label: Text(t('coordinate.convert'))),
              if (_error != null) ...[const SizedBox(height: 16), Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))],
              if (value != null) ...[
                const SizedBox(height: 24),
                _ResultCard(title: t('coordinate.decimal'), value: value.decimalDegrees, copyTooltip: t('common.copy'), onCopy: () => _copy(value.decimalDegrees)),
                const SizedBox(height: 12),
                _ResultCard(title: t('coordinate.dms'), value: value.dms, copyTooltip: t('common.copy'), onCopy: () => _copy(value.dms)),
                const SizedBox(height: 12),
                Text(t('coordinate.hemisphere'), style: Theme.of(context).textTheme.bodySmall),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.title, required this.value, required this.copyTooltip, required this.onCopy});
  final String title;
  final String value;
  final String copyTooltip;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) => Card(child: ListTile(title: Text(title), subtitle: SelectableText(value), trailing: IconButton(tooltip: copyTooltip, onPressed: onCopy, icon: const Icon(Icons.copy))));
}
