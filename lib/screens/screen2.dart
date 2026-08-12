import 'package:flutter/material.dart';
import '../config/routes.dart';
import '../widgets/nav_button.dart';

class Screen2 extends StatefulWidget {
  const Screen2({super.key});

  @override
  State<Screen2> createState() => _Screen2State();
}

class _Screen2State extends State<Screen2> {
  var _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trick and Mock(Screen 2👾)'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                '$_counter',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _counter >= 10 ? 'Too much😈' : '',
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FloatingActionButton(
                onPressed: _incrementCounter,
                child: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  // TODO
                },
                child: const Text('mock 1🙂'),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () {
                  // TODO
                },
                child: const Text('mock 2🙂'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[
              NavButton(label: 'Go to HomeApp🏠', routeName: AppRoutes.home),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[
              NavButton(label: 'Go to Screen 3🥐', routeName: AppRoutes.screen3),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[
              NavButton(label: 'Go to Screen 4🎸', routeName: AppRoutes.screen4),
            ],
          ),
        ],
      ),
    );
  }
}
