import 'package:flutter/material.dart';
import '../config/routes.dart';
import '../shared/display/display_scope.dart';
import 'generic_screen.dart';

enum _ViewMode { list, grid }

class HubScreen extends StatefulWidget {
  const HubScreen({super.key});

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  List<ScreenData> _all = [];
  List<ScreenData> _filtered = [];
  _ViewMode _mode = _ViewMode.grid;
  final _searchCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_filter);
  }

  Future<void> _load() async {
    final screens = await ScreensConfig.load();
    if (mounted) setState(() { _all = screens; _filtered = screens; _loading = false; });
  }

  void _filter() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = query.isEmpty ? _all : _all.where((s) => s.name.toLowerCase().contains(query) || s.title.toLowerCase().contains(query) || s.description.toLowerCase().contains(query) || s.category.toLowerCase().contains(query)).toList();
    });
  }

  void _navigate(ScreenData s) => Navigator.pushNamed(context, '/screen${s.id}');

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    String t(String key) => display.text(key);
    return Scaffold(
      appBar: AppBar(
        title: Text(t('hub.title')),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(tooltip: t('hub.apiTooltip'), icon: const Icon(Icons.api), onPressed: () => Navigator.pushNamed(context, AppRoutes.externalApi)),
          IconButton(tooltip: t('hub.mcpTooltip'), icon: const Icon(Icons.hub_outlined), onPressed: () => Navigator.pushNamed(context, AppRoutes.externalMcp)),
          IconButton(tooltip: t('hub.listView'), icon: const Icon(Icons.list), onPressed: () => setState(() => _mode = _ViewMode.list), color: _mode == _ViewMode.list ? Colors.blue : null),
          IconButton(tooltip: t('hub.gridView'), icon: const Icon(Icons.grid_view), onPressed: () => setState(() => _mode = _ViewMode.grid), color: _mode == _ViewMode.grid ? Colors.blue : null),
          const DisplayLocalePicker(compact: true),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(hintText: t('hub.search'), prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)), contentPadding: const EdgeInsets.symmetric(vertical: 8)),
            ),
          ),
        ),
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _filtered.isEmpty ? Center(child: Text(t('hub.empty'))) : _mode == _ViewMode.list ? _buildList() : _buildGrid(),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => Navigator.pushNamed(context, AppRoutes.home), icon: const Icon(Icons.home), label: Text(t('common.home'))),
    );
  }

  Widget _buildList() => ListView.builder(itemCount: _filtered.length, itemBuilder: (context, i) { final s = _filtered[i]; return ListTile(key: Key('screen-item-${s.id}'), leading: CircleAvatar(child: Text(s.emoji)), title: Text('${s.name}: ${s.title}'), subtitle: Text(s.description, maxLines: 1, overflow: TextOverflow.ellipsis), trailing: const Icon(Icons.chevron_right), onTap: () => _navigate(s)); });

  Widget _buildGrid() => GridView.builder(padding: const EdgeInsets.all(12), gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 160, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.9), itemCount: _filtered.length, itemBuilder: (context, i) { final s = _filtered[i]; return InkWell(key: Key('screen-grid-${s.id}'), onTap: () => _navigate(s), borderRadius: BorderRadius.circular(12), child: Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.all(10), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(s.emoji, style: const TextStyle(fontSize: 32)), const SizedBox(height: 6), Text(s.name, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center), const SizedBox(height: 4), Text(s.title, style: Theme.of(context).textTheme.labelSmall, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis)])))); });
}
