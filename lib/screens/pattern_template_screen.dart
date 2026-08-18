import 'package:flutter/material.dart';

import '../shared/display/display_scope.dart';

enum PatternScreenTemplate {
  list,
  detail,
  form,
  search,
  tabs,
  bottomNavigation,
  drawer,
  dialog,
  grid,
  asyncState,
  settings,
}

PatternScreenTemplate templateForScreenId(int screenId) {
  final index = ((screenId - 1) ~/ 18)
      .clamp(0, PatternScreenTemplate.values.length - 1)
      .toInt();
  return PatternScreenTemplate.values[index];
}

PatternScreenTemplate templateFromName(String? name) {
  if (name == null) return PatternScreenTemplate.list;
  for (final value in PatternScreenTemplate.values) {
    if (value.name == name) return value;
  }
  return PatternScreenTemplate.list;
}

String templateLabel(DisplayController display, PatternScreenTemplate template) {
  switch (template) {
    case PatternScreenTemplate.list:
      return display.text('patternTemplate.list');
    case PatternScreenTemplate.detail:
      return display.text('patternTemplate.detail');
    case PatternScreenTemplate.form:
      return display.text('patternTemplate.form');
    case PatternScreenTemplate.search:
      return display.text('patternTemplate.search');
    case PatternScreenTemplate.tabs:
      return display.text('patternTemplate.tabs');
    case PatternScreenTemplate.bottomNavigation:
      return display.text('patternTemplate.bottomNavigation');
    case PatternScreenTemplate.drawer:
      return display.text('patternTemplate.drawer');
    case PatternScreenTemplate.dialog:
      return display.text('patternTemplate.dialog');
    case PatternScreenTemplate.grid:
      return display.text('patternTemplate.grid');
    case PatternScreenTemplate.asyncState:
      return display.text('patternTemplate.asyncState');
    case PatternScreenTemplate.settings:
      return display.text('patternTemplate.settings');
  }
}

class PatternTemplateBody extends StatefulWidget {
  final int screenId;
  final String title;
  final String description;
  final String? templateOverride;

  const PatternTemplateBody({
    super.key,
    required this.screenId,
    required this.title,
    required this.description,
    this.templateOverride,
  });

  @override
  State<PatternTemplateBody> createState() => _PatternTemplateBodyState();
}

class _PatternTemplateBodyState extends State<PatternTemplateBody> {
  final _controller = TextEditingController();
  int _selectedIndex = 0;
  bool _enabled = true;
  bool _loading = false;

  PatternScreenTemplate get template {
    final override = widget.templateOverride;
    if (override != null && override.isNotEmpty) {
      return templateFromName(override);
    }
    return templateForScreenId(widget.screenId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    switch (template) {
      case PatternScreenTemplate.list:
        return ListView.separated(
          itemCount: 6,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) => ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text(display.text(
              'patternTemplate.listItem',
              arguments: {'title': widget.title, 'n': index + 1},
            )),
            subtitle: Text(widget.description),
          ),
        );
      case PatternScreenTemplate.detail:
        return _padded(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(widget.description),
              const SizedBox(height: 20),
              const Divider(),
              Text(display.text(
                'patternTemplate.screenIdLabel',
                arguments: {'id': widget.screenId},
              )),
            ],
          ),
        );
      case PatternScreenTemplate.form:
        return _padded(
          Column(
            children: [
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: display.text('patternTemplate.sampleInputLabel'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(display.text(
                        'patternTemplate.submitted',
                        arguments: {'value': _controller.text},
                      )),
                    ),
                  ),
                  child: Text(display.text('patternTemplate.submit')),
                ),
              ),
            ],
          ),
        );
      case PatternScreenTemplate.search:
        return _padded(
          Column(
            children: [
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: display.text('patternTemplate.searchHint'),
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.manage_search),
                title: Text(_controller.text.isEmpty
                    ? display.text('patternTemplate.typeToFilter')
                    : display.text(
                        'patternTemplate.resultFor',
                        arguments: {'query': _controller.text},
                      )),
                subtitle: Text(widget.description),
              ),
            ],
          ),
        );
      case PatternScreenTemplate.tabs:
        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              TabBar(tabs: [
                Tab(text: display.text('patternTemplate.tabOverview')),
                Tab(text: display.text('patternTemplate.tabCode')),
                Tab(text: display.text('patternTemplate.tabNotes')),
              ]),
              Expanded(
                child: TabBarView(
                  children: [
                    Center(child: Text(widget.title)),
                    const Center(child: Icon(Icons.code, size: 48)),
                    Center(child: Text(widget.description)),
                  ],
                ),
              ),
            ],
          ),
        );
      case PatternScreenTemplate.bottomNavigation:
        return Column(
          children: [
            Expanded(
              child: Center(
                child: Text(display.text(
                  'patternTemplate.destination',
                  arguments: {'n': _selectedIndex + 1, 'title': widget.title},
                )),
              ),
            ),
            NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (value) => setState(() => _selectedIndex = value),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  label: display.text('patternTemplate.navHome'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.list_alt),
                  label: display.text('patternTemplate.navPatterns'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.info_outline),
                  label: display.text('patternTemplate.navAbout'),
                ),
              ],
            ),
          ],
        );
      case PatternScreenTemplate.drawer:
        return _padded(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(display.text('patternTemplate.drawerSampleTitle'),
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.home),
                title: Text(display.text('patternTemplate.drawerHome')),
              ),
              ListTile(
                leading: const Icon(Icons.book),
                title: Text(display.text('patternTemplate.drawerLibrary')),
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: Text(display.text('patternTemplate.drawerSettings')),
              ),
            ],
          ),
        );
      case PatternScreenTemplate.dialog:
        return Center(
          child: FilledButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: Text(display.text('patternTemplate.dialogOpen')),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(widget.title),
                content: Text(widget.description),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(display.text('patternTemplate.dialogClose')),
                  ),
                ],
              ),
            ),
          ),
        );
      case PatternScreenTemplate.grid:
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 180,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: 8,
          itemBuilder: (context, index) => Card(
            child: Center(
              child: Text(
                '${widget.title}\n#${index + 1}',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      case PatternScreenTemplate.asyncState:
        return Center(
          child: _loading
              ? const CircularProgressIndicator()
              : FilledButton.icon(
                  icon: const Icon(Icons.sync),
                  label: Text(display.text('patternTemplate.asyncSimulate')),
                  onPressed: () async {
                    setState(() => _loading = true);
                    await Future<void>.delayed(const Duration(milliseconds: 500));
                    if (!mounted) return;
                    setState(() => _loading = false);
                  },
                ),
        );
      case PatternScreenTemplate.settings:
        return _padded(
          Column(
            children: [
              SwitchListTile(
                title: Text(display.text('patternTemplate.settingsEnableOption')),
                subtitle: Text(widget.description),
                value: _enabled,
                onChanged: (value) => setState(() => _enabled = value),
              ),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: Text(display.text('patternTemplate.settingsThemePreference')),
                trailing: Text(display.text('patternTemplate.settingsSystem')),
                onTap: () {},
              ),
            ],
          ),
        );
    }
  }

  Widget _padded(Widget child) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: child,
      );
}
