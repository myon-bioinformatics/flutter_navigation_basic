import 'package:flutter/material.dart';

class _CounterScope extends InheritedWidget {
  const _CounterScope({required this.left, required this.right, required super.child});
  final int left;
  final int right;

  static _CounterScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_CounterScope>();
    assert(scope != null, 'Counter scope is missing');
    return scope!;
  }

  @override
  bool updateShouldNotify(_CounterScope oldWidget) =>
      left != oldWidget.left || right != oldWidget.right;
}

class _CounterModel extends InheritedModel<String> {
  const _CounterModel({required this.left, required this.right, required super.child});
  final int left;
  final int right;

  static int read(BuildContext context, String aspect) {
    final model = InheritedModel.inheritFrom<_CounterModel>(context, aspect: aspect);
    assert(model != null, 'Counter model is missing');
    return aspect == 'left' ? model!.left : model!.right;
  }

  @override
  bool updateShouldNotify(_CounterModel oldWidget) =>
      left != oldWidget.left || right != oldWidget.right;

  @override
  bool updateShouldNotifyDependent(
    _CounterModel oldWidget, Set<String> dependencies) =>
      (dependencies.contains('left') && left != oldWidget.left) ||
      (dependencies.contains('right') && right != oldWidget.right);
}

class _ValueDisplay extends StatelessWidget {
  const _ValueDisplay({required this.aspect, required this.selective});
  final String aspect;
  final bool selective;

  @override
  Widget build(BuildContext context) {
    final value = selective
        ? _CounterModel.read(context, aspect)
        : (aspect == 'left' ? _CounterScope.of(context).left : _CounterScope.of(context).right);
    return Text('$aspect: $value');
  }
}

/// Flutter-native propagation/notification, without GetX or a fake success service.
class InheritedCatalogueExample extends StatefulWidget {
  const InheritedCatalogueExample({
    super.key,
    required this.title,
    required this.description,
    required this.selective,
  });
  final String title;
  final String description;
  final bool selective;

  @override
  State<InheritedCatalogueExample> createState() => _InheritedCatalogueExampleState();
}

class _InheritedCatalogueExampleState extends State<InheritedCatalogueExample> {
  int left = 0;
  int right = 0;

  @override
  Widget build(BuildContext context) {
    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const _ValueDisplay(aspect: 'left', selective: false),
        const _ValueDisplay(aspect: 'right', selective: false),
        ElevatedButton(
          onPressed: () => setState(() => left++),
          child: const Text('左を加算'),
        ),
        ElevatedButton(
          onPressed: () => setState(() => right++),
          child: const Text('右を加算'),
        ),
      ],
    );
    final selectiveControls = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const _ValueDisplay(aspect: 'left', selective: true),
        const _ValueDisplay(aspect: 'right', selective: true),
        ElevatedButton(
          onPressed: () => setState(() => left++),
          child: const Text('左を加算'),
        ),
        ElevatedButton(
          onPressed: () => setState(() => right++),
          child: const Text('右を加算'),
        ),
      ],
    );
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.description),
            if (widget.selective)
              _CounterModel(left: left, right: right, child: selectiveControls)
            else
              _CounterScope(left: left, right: right, child: controls),
          ],
        ),
      ),
    );
  }
}
