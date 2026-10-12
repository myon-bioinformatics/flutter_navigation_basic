import 'package:flutter/material.dart';

import '../shared/catalog/catalog_search.dart';
import '../config/routes.dart';
import '../shared/display/display_scope.dart';
import 'generic_screen.dart';
import '../shared/widgets/standard_page_shell.dart';

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
    if (mounted) {
      setState(() {
        _all = screens;
        _filtered = searchCatalog(screens, _searchCtrl.text);
        _loading = false;
      });
    }
  }

  void _filter() {
    setState(() {
      _filtered = searchCatalog(_all, _searchCtrl.text);
    });
  }

  void _navigate(ScreenData s) {
    Navigator.pushNamed(context, '/screen${s.screenDataId}');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    return StandardPageShell(
      currentRouteName: AppRoutes.hub,
      title: display.text('hub.title'),
      headerActions: [
        IconButton(
          tooltip: display.text('mockApi.title'),
          icon: const Icon(Icons.api),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.externalApi),
        ),
        IconButton(
          tooltip: display.text('mcp.title'),
          icon: const Icon(Icons.hub_outlined),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.externalMcp),
        ),
        Semantics(
          identifier: 'hub-list-view',
          container: true,
          child: IconButton(
            tooltip: display.text('hub.listViewTooltip'),
            icon: const Icon(Icons.list),
            onPressed: () => setState(() => _mode = _ViewMode.list),
            color: _mode == _ViewMode.list ? Colors.blue : null,
          ),
        ),
        IconButton(
          tooltip: display.text('hub.gridViewTooltip'),
          icon: const Icon(Icons.grid_view),
          onPressed: () => setState(() => _mode = _ViewMode.grid),
          color: _mode == _ViewMode.grid ? Colors.blue : null,
        ),
      ],
      subHeader: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Semantics(
            identifier: 'hub-search',
            container: true,
            explicitChildNodes: true,
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: display.text('hub.searchHint'),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ),
      ),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _filtered.isEmpty
          ? Center(child: Text(display.text('hub.empty')))
          : _mode == _ViewMode.list
          ? _buildList()
          : _buildGrid(),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      itemCount: _filtered.length,
      itemBuilder: (context, i) {
        final s = _filtered[i];
        return Semantics(
          identifier: 'hub-result-${s.screenDataId}',
          container: true,
          explicitChildNodes: true,
          child: ListTile(
            key: Key('screen-item-${s.screenDataId}'),
            leading: CircleAvatar(child: Text(s.emoji)),
            title: Text('${s.name}: ${s.title}'),
            subtitle: Text(
              s.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _navigate(s),
          ),
        );
      },
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.9,
      ),
      itemCount: _filtered.length,
      itemBuilder: (context, i) {
        final s = _filtered[i];
        return InkWell(
          key: Key('screen-grid-${s.screenDataId}'),
          onTap: () => _navigate(s),
          borderRadius: BorderRadius.circular(12),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(s.emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: 6),
                  Text(
                    s.name,
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.title,
                    style: Theme.of(context).textTheme.labelSmall,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
