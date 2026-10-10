import 'package:flutter/material.dart';

/// Native interaction playground; business/data operations can live in Python.
/// All IDs are demo-only and this widget is exposed only by E2E builds.
class InteractivePatternExample extends StatefulWidget {
  const InteractivePatternExample({super.key, required this.patternId});
  final int patternId;
  @override
  State<InteractivePatternExample> createState() => _InteractivePatternExampleState();
}

class _InteractivePatternExampleState extends State<InteractivePatternExample> {
  final _animatedKey = GlobalKey<AnimatedListState>();
  final _items = <String>['A', 'B', 'C'];
  final _selected = <String>{};
  int _inserted = 0;

  bool get _reordering =>
      widget.patternId == 171 || widget.patternId == 172 || widget.patternId == 184;
  bool get _animating => widget.patternId == 174 || widget.patternId == 175;

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final value = _items.removeAt(oldIndex);
      _items.insert(newIndex, value);
    });
  }

  Widget _entry(String item) => Semantics(
    identifier: 'interaction-item-$item',
    child: Card(
      child: ListTile(title: Text(item), trailing: const Icon(Icons.drag_handle)),
    ),
  );

  Widget _reorderList() => ReorderableListView.builder(
    buildDefaultDragHandles: false,
    itemCount: _items.length,
    onReorder: _onReorder,
    itemBuilder: (context, index) {
      final item = _items[index];
      final child = _entry(item);
      return Container(
        key: ValueKey(item),
        child: widget.patternId == 184
            ? ReorderableDelayedDragStartListener(index: index, child: child)
            : ReorderableDragStartListener(index: index, child: child),
      );
    },
  );

  Widget _grid() => GridView.count(
    crossAxisCount: 2,
    childAspectRatio: 2.4,
    children: [
      for (final item in _items)
        DragTarget<String>(
          onWillAcceptWithDetails: (details) => details.data != item,
          onAcceptWithDetails: (details) => setState(() {
            final a = _items.indexOf(details.data);
            final b = _items.indexOf(item);
            if (a < 0 || b < 0 || a == b) return;
            final old = _items[a];
            _items[a] = _items[b];
            _items[b] = old;
          }),
          builder: (context, accepted, rejected) => LongPressDraggable<String>(
            data: item,
            feedback: Material(
              elevation: 4,
              child: SizedBox(width: 110, height: 70, child: Center(child: Text(item))),
            ),
            childWhenDragging: const SizedBox.shrink(),
            child: Semantics(
              identifier: 'interaction-item-$item',
              child: Card(
                child: Center(child: Text(item)),
              ),
            ),
          ),
        ),
    ],
  );

  Widget _animatedList() => AnimatedList(
    key: _animatedKey,
    initialItemCount: _items.length,
    itemBuilder: (context, index, animation) => SizeTransition(
      sizeFactor: animation,
      child: _entry(_items[index]),
    ),
  );

  void _insert() {
    final next = 'N${++_inserted}';
    setState(() => _items.insert(0, next));
    _animatedKey.currentState?.insertItem(0, duration: const Duration(milliseconds: 180));
  }

  void _remove() {
    if (_items.isEmpty) return;
    final deleted = _items.removeAt(0);
    _animatedKey.currentState?.removeItem(
      0,
      (context, animation) => SizeTransition(
        sizeFactor: animation,
        child: _entry(deleted),
      ),
      duration: const Duration(milliseconds: 180),
    );
    setState(() {});
  }

  Widget _multiSelect() => ListView(
    children: [
      for (final item in _items)
        Semantics(
          identifier: 'interaction-item-$item',
          child: CheckboxListTile(
            key: ValueKey('select-$item'),
            title: Text(item),
            value: _selected.contains(item),
            onChanged: (selected) => setState(() {
              if (selected == true) {
                _selected.add(item);
              } else {
                _selected.remove(item);
              }
            }),
          ),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final id = widget.patternId;
    final title = switch (id) {
      171 => 'SortableList',
      172 => 'ReorderList',
      173 => 'DndGrid',
      174 => 'InsertItem',
      175 => 'RemoveItem',
      183 => 'MultiSelect',
      184 => 'DragReorder',
      _ => 'Unsupported',
    };
    return Scaffold(
      appBar: AppBar(title: Text('Pattern $id: $title')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Flutter標準Widgetで実際に操作する例。外部CLIとデータ処理は別境界。'),
            Semantics(
              identifier: 'interaction-order',
              child: Text('順序: ${_items.join(", ")}'),
            ),
            if (id == 183) ...[
              Text('選択数: ${_selected.length}'),
              ElevatedButton(
                onPressed: _selected.isEmpty
                    ? null
                    : () => setState(() {
                          _items.removeWhere(_selected.contains);
                          _selected.clear();
                        }),
                child: const Text('選択項目を削除'),
              ),
            ],
            if (_animating) ...[
              if (id == 174)
                ElevatedButton(onPressed: _insert, child: const Text('挿入'))
              else
                ElevatedButton(
                  onPressed: _items.isEmpty ? null : _remove,
                  child: const Text('削除'),
                ),
            ],
            Expanded(
              child: _reordering
                  ? _reorderList()
                  : id == 173
                      ? _grid()
                      : _animating
                          ? _animatedList()
                          : id == 183
                              ? _multiSelect()
                              : const Center(child: Text('未対応の操作')),
            ),
          ],
        ),
      ),
    );
  }
}
