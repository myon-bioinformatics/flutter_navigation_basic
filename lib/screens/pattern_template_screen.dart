import 'package:flutter/material.dart';

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
  final index = ((screenId - 1) ~/ 18).clamp(0, PatternScreenTemplate.values.length - 1);
  return PatternScreenTemplate.values[index];
}

String templateLabel(PatternScreenTemplate template) {
  switch (template) {
    case PatternScreenTemplate.list:
      return 'List';
    case PatternScreenTemplate.detail:
      return 'Detail';
    case PatternScreenTemplate.form:
      return 'Form';
    case PatternScreenTemplate.search:
      return 'Search';
    case PatternScreenTemplate.tabs:
      return 'Tabs';
    case PatternScreenTemplate.bottomNavigation:
      return 'Bottom navigation';
    case PatternScreenTemplate.drawer:
      return 'Drawer';
    case PatternScreenTemplate.dialog:
      return 'Dialog';
    case PatternScreenTemplate.grid:
      return 'Grid';
    case PatternScreenTemplate.asyncState:
      return 'Async state';
    case PatternScreenTemplate.settings:
      return 'Settings';
  }
}

class PatternTemplateBody extends StatefulWidget {
  final int screenId;
  final String title;
  final String description;

  const PatternTemplateBody({
    super.key,
    required this.screenId,
    required this.title,
    required this.description,
  });

  @override
  State<PatternTemplateBody> createState() => _PatternTemplateBodyState();
}

class _PatternTemplateBodyState extends State<PatternTemplateBody> {
  final _controller = TextEditingController();
  int _selectedIndex = 0;
  bool _enabled = true;
  bool _loading = false;

  PatternScreenTemplate get template => templateForScreenId(widget.screenId);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (template) {
      case PatternScreenTemplate.list:
        return ListView.separated(
          itemCount: 6,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) => ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text('${widget.title} item ${index + 1}'),
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
              Text('Screen ID: ${widget.screenId}'),
            ],
          ),
        );
      case PatternScreenTemplate.form:
        return _padded(
          Column(
            children: [
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Sample input',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Submitted: ${_controller.text}')),
                  ),
                  child: const Text('Submit'),
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
                decoration: const InputDecoration(
                  hintText: 'Search this sample',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.manage_search),
                title: Text(_controller.text.isEmpty
                    ? 'Type a query to filter'
                    : 'Result for “${_controller.text}”'),
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
              const TabBar(tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'Code'),
                Tab(text: 'Notes'),
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
                child: Text('Destination ${_selectedIndex + 1}: ${widget.title}'),
              ),
            ),
            NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (value) => setState(() => _selectedIndex = value),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.list_alt), label: 'Patterns'),
                NavigationDestination(icon: Icon(Icons.info_outline), label: 'About'),
              ],
            ),
          ],
        );
      case PatternScreenTemplate.drawer:
        return _padded(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Drawer-style navigation sample',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              const ListTile(leading: Icon(Icons.home), title: Text('Home')),
              const ListTile(leading: Icon(Icons.book), title: Text('Library')),
              const ListTile(leading: Icon(Icons.settings), title: Text('Settings')),
            ],
          ),
        );
      case PatternScreenTemplate.dialog:
        return Center(
          child: FilledButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open dialog'),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(widget.title),
                content: Text(widget.description),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
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
            child: Center(child: Text('${widget.title}\n#${index + 1}', textAlign: TextAlign.center)),
          ),
        );
      case PatternScreenTemplate.asyncState:
        return Center(
          child: _loading
              ? const CircularProgressIndicator()
              : FilledButton.icon(
                  icon: const Icon(Icons.sync),
                  label: const Text('Simulate async task'),
                  onPressed: () async {
                    setState(() => _loading = true);
                    await Future<void>.delayed(const Duration(milliseconds: 500));
                    if (mounted) setState(() => _loading = false);
                  },
                ),
        );
      case PatternScreenTemplate.settings:
        return _padded(
          Column(
            children: [
              SwitchListTile(
                title: const Text('Enable sample option'),
                subtitle: Text(widget.description),
                value: _enabled,
                onChanged: (value) => setState(() => _enabled = value),
              ),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Theme preference'),
                trailing: const Text('System'),
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
