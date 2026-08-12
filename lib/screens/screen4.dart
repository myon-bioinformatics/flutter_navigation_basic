import 'dart:math';
import 'package:flutter/material.dart';
import '../config/routes.dart';
import '../data/composer.dart';
import '../widgets/nav_button.dart';

class Screen4 extends StatefulWidget {
  const Screen4({super.key});

  @override
  State<Screen4> createState() => _Screen4State();
}

class _Screen4State extends State<Screen4> {
  final String tonicKey =
      Composer.diatonicScaleList[Random().nextInt(Composer.diatonicScaleList.length)];
  final int bpm = 100 + Random().nextInt(61);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Composition(Screen 4🎸)'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                "Key: $tonicKey, BPM: $bpm",
                style: Theme.of(context).textTheme.headlineMedium,
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
              NavButton(label: 'Go to Screen 2👾', routeName: AppRoutes.screen2),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[
              NavButton(label: 'Go to Screen 3🥐', routeName: AppRoutes.screen3),
            ],
          ),
        ],
      ),
    );
  }
}
