import 'dart:async';

import 'package:flutter/material.dart';

/// A small notifier-style state object using Flutter's built-in ValueNotifier.
/// This is not a Riverpod StateNotifier package replacement.
class _CountNotifier extends ValueNotifier<int> {
  _CountNotifier() : super(0);
  void increment() => value++;
  void reset() => value = 0;
}

enum _CountEvent { increment, reset }

/// Minimal BLoC-like event/state separation using dart:async, no packages.
class _CountBloc {
  final _events = StreamController<_CountEvent>(sync: true);
  final _states = StreamController<int>.broadcast(sync: true);
  late final StreamSubscription<_CountEvent> _subscription;
  int _value = 0;

  _CountBloc() {
    _subscription = _events.stream.listen((event) {
      _value = event == _CountEvent.increment ? _value + 1 : 0;
      _states.add(_value);
    });
  }

  Stream<int> get stream => _states.stream;
  void increment() => _events.add(_CountEvent.increment);
  void reset() => _events.add(_CountEvent.reset);

  void dispose() {
    unawaited(_subscription.cancel());
    unawaited(_events.close());
    unawaited(_states.close());
  }
}

class StateArchitectureExample extends StatefulWidget {
  const StateArchitectureExample({
    super.key,
    required this.title,
    required this.description,
    required this.bloc,
  });
  final String title;
  final String description;
  final bool bloc;

  @override
  State<StateArchitectureExample> createState() => _StateArchitectureExampleState();
}

class _StateArchitectureExampleState extends State<StateArchitectureExample> {
  final _notifier = _CountNotifier();
  final _bloc = _CountBloc();

  @override
  void dispose() {
    _notifier.dispose();
    _bloc.dispose();
    super.dispose();
  }

  void _increment() {
    if (widget.bloc) {
      _bloc.increment();
    } else {
      _notifier.increment();
    }
  }

  void _reset() {
    if (widget.bloc) {
      _bloc.reset();
    } else {
      _notifier.reset();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.description),
          const SizedBox(height: 12),
          if (widget.bloc)
            StreamBuilder<int>(
              stream: _bloc.stream,
              initialData: 0,
              builder: (context, snapshot) => Text('カウント: ${snapshot.data ?? 0}'),
            )
          else
            ValueListenableBuilder<int>(
              valueListenable: _notifier,
              builder: (context, value, child) => Text('カウント: $value'),
            ),
          ElevatedButton(onPressed: _increment, child: const Text('加算')),
          TextButton(onPressed: _reset, child: const Text('リセット')),
        ],
      ),
    ),
  );
}
