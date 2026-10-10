import 'package:flutter/material.dart';

enum CounterArchitecture { mvc, mvvm, mvp, clean, atom }

abstract interface class _CounterPort implements Listenable {
  int get count;
  void increment();
  void reset();
  void dispose();
}

class _Model {
  int count = 0;
}

/// MVC: Controller changes an independent Model and notifies its View.
class _MvcController extends ChangeNotifier implements _CounterPort {
  final _model = _Model();
  @override int get count => _model.count;
  @override void increment() { _model.count++; notifyListeners(); }
  @override void reset() { _model.count = 0; notifyListeners(); }
}

/// MVVM: ViewModel exposes an observable value directly to its View.
class _MvvmViewModel extends ValueNotifier<int> implements _CounterPort {
  _MvvmViewModel() : super(0);
  @override int get count => value;
  @override void increment() => value++;
  @override void reset() => value = 0;
}

/// MVP: Presenter mediates between a passive view and Model.
class _MvpPresenter extends ChangeNotifier implements _CounterPort {
  final _model = _Model();
  @override int get count => _model.count;
  @override void increment() { _model.count++; notifyListeners(); }
  @override void reset() { _model.count = 0; notifyListeners(); }
}

/// Clean-style: UI adapter uses an application use case and repository port.
abstract interface class _CounterRepository {
  int read();
  void write(int value);
}
class _InMemoryCounterRepository implements _CounterRepository {
  int _count = 0;
  @override int read() => _count;
  @override void write(int value) { _count = value; }
}
class _CounterUseCase {
  const _CounterUseCase();
  int increment(int current) => current + 1;
  int reset() => 0;
}
class _CleanAdapter extends ChangeNotifier implements _CounterPort {
  final _CounterRepository _repository = _InMemoryCounterRepository();
  final _CounterUseCase _useCase = const _CounterUseCase();
  @override int get count => _repository.read();
  @override void increment() { _repository.write(_useCase.increment(count)); notifyListeners(); }
  @override void reset() { _repository.write(_useCase.reset()); notifyListeners(); }
}

class _CounterHost extends StatefulWidget {
  const _CounterHost({required this.architecture});
  final CounterArchitecture architecture;
  @override State<_CounterHost> createState() => _CounterHostState();
}
class _CounterHostState extends State<_CounterHost> {
  late final _CounterPort _port;
  @override void initState() {
    super.initState();
    _port = switch (widget.architecture) {
      CounterArchitecture.mvc => _MvcController(),
      CounterArchitecture.mvvm => _MvvmViewModel(),
      CounterArchitecture.mvp => _MvpPresenter(),
      CounterArchitecture.clean => _CleanAdapter(),
      CounterArchitecture.atom => throw StateError('Use atom host'),
    };
  }
  @override void dispose() { _port.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => ListenableBuilder(
    listenable: _port,
    builder: (context, child) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('カウント: ${_port.count}'),
        ElevatedButton(onPressed: _port.increment, child: const Text('加算')),
        TextButton(onPressed: _port.reset, child: const Text('リセット')),
      ],
    ),
  );
}

class _AtomHost extends StatefulWidget {
  const _AtomHost();
  @override State<_AtomHost> createState() => _AtomHostState();
}
class _AtomHostState extends State<_AtomHost> {
  final _left = ValueNotifier<int>(0);
  final _right = ValueNotifier<int>(0);
  @override void dispose() { _left.dispose(); _right.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ValueListenableBuilder<int>(
        valueListenable: _left,
        builder: (context, value, child) => Text('left: $value'),
      ),
      ValueListenableBuilder<int>(
        valueListenable: _right,
        builder: (context, value, child) => Text('right: $value'),
      ),
      ElevatedButton(onPressed: () => _left.value++, child: const Text('左を加算')),
      ElevatedButton(onPressed: () => _right.value++, child: const Text('右を加算')),
    ],
  );
}

/// Small runnable sketches of responsibilities, not full architecture frameworks.
class CounterArchitectureExample extends StatelessWidget {
  const CounterArchitectureExample({
    super.key,
    required this.title,
    required this.description,
    required this.architecture,
  });
  final String title;
  final String description;
  final CounterArchitecture architecture;
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(description),
          const SizedBox(height: 12),
          const Text('Flutter標準APIによる最小構成の実動作例。フレームワーク全機能の実装ではありません。'),
          const SizedBox(height: 16),
          if (architecture == CounterArchitecture.atom)
            const _AtomHost()
          else
            _CounterHost(architecture: architecture),
        ],
      ),
    ),
  );
}
