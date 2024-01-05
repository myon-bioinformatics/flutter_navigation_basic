import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'config.dart';
import 'dart:math';

void main() {
  runApp(const MaterialApp(
    title: 'Navigation Basics',
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _Screen1State();
}

class _Screen1State extends State<MyApp> {
  DateTime get nowadays => DateTime.now();
  get today => DateFormat('yyyy/MM/dd(E)').format(nowadays);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen1: HomeApp🏠'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center Align
            children: <Widget>[
              Text(
                today,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          const SizedBox(height: 20), // Space between Row method
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center Align
            children: <Widget>[
              ElevatedButton(
                child: const Text('Go to Screen 2👾'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Screen2()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20), // Space between Row method
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center Align
            children: <Widget>[
              ElevatedButton(
                child: const Text('Go to Screen 3🥐'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Screen3()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20), // Space between Row method
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center Align
            children: <Widget>[
              ElevatedButton(
                child: const Text('Go to Screen 4🎸'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Screen4()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
            mainAxisAlignment: MainAxisAlignment.center, // Center Align
            children: <Widget>[
              Text(
                '$_counter',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          const SizedBox(height: 20), // Space between Row method
          Text(
            _counter >= 10 ? 'Too much😈' : '',
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 20), // Space between Row method
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center Align
            children: <Widget>[
              FloatingActionButton(
                onPressed: _incrementCounter,
                child: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 20), // Space between Row method
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center Align
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  // TODO
                },
                child: const Text('mock 1🙂'),
              ),
              const SizedBox(width: 20), // Space between ElevatedButton method
              ElevatedButton(
                onPressed: () {
                  // TODO
                },
                child: const Text('mock 2🙂'),
              ),
            ],
          ),
          const SizedBox(height: 20), // Space between Row method
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center Align
            children: <Widget>[
              ElevatedButton(
                child: const Text('Go to HomeApp🏠'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyApp()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20), // Space between Row method
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center Align
            children: <Widget>[
              ElevatedButton(
                child: const Text('Go to Screen 3🥐'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Screen3()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20), // Space between Row method
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center Align
            children: <Widget>[
              ElevatedButton(
                child: const Text('Go to Screen 4🎸'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Screen4()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Screen3 extends StatefulWidget {
  const Screen3({super.key});

  @override
  State<Screen3> createState() => _Screen3State();
}

class _Screen3State extends State<Screen3> {
  String irony = Ironies.ironicList[Random().nextInt(5)];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Irony(Screen 3🥐)'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center Align
            children: <Widget>[
              Text(
                '$irony',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          const SizedBox(height: 20), // Space between Row method
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center Align
            children: <Widget>[
              ElevatedButton(
                child: const Text('Go to HomeApp🏠'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyApp()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20), // Space between Row method
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center Align
            children: <Widget>[
              ElevatedButton(
                child: const Text('Go to Screen 2👾'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Screen2()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20), // Space between Row method
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center Align
            children: <Widget>[
              ElevatedButton(
                child: const Text('Go to Screen 4🎸'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Screen4()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Screen4 extends StatefulWidget {
  const Screen4({super.key});

  @override
  State<Screen4> createState() => _Screen4State();
}

class _Screen4State extends State<Screen4> {
  String tonickey = Composer.diatonicScaleList[Random().nextInt(12)];
  int bpm = 100 + Random().nextInt(61);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Composion(Screen 4🎸)'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center Align
            children: <Widget>[
              Text(
                "Key: $tonickey, BPM: $bpm",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          const SizedBox(height: 20), // Space between Row method
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center Align
            children: <Widget>[
              ElevatedButton(
                child: const Text('Go to HomeApp🏠'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyApp()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20), // Space between Row method
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center Align
            children: <Widget>[
              ElevatedButton(
                child: const Text('Go to Screen 2👾'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Screen2()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20), // Space between Row method
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center Align
            children: <Widget>[
              ElevatedButton(
                child: const Text('Go to Screen 3🥐'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Screen3()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
