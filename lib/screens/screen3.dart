import 'dart:math';
import 'package:flutter/material.dart';
import '../config/routes.dart';
import '../data/ironies.dart';
import '../widgets/nav_button.dart';

class Screen3 extends StatefulWidget {
  const Screen3({super.key});

  @override
  State<Screen3> createState() => _Screen3State();
}

class _Screen3State extends State<Screen3> {
  final String irony = Ironies.ironicList[Random().nextInt(Ironies.ironicList.length)];

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
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                irony,
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
              NavButton(label: 'Go to Screen 4🎸', routeName: AppRoutes.screen4),
            ],
          ),
        ],
      ),
    );
  }
}
