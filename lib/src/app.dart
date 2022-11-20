import 'dart:io';

import 'package:flutter/material.dart';

import 'pages/home_page.dart';

class App extends StatelessWidget {
  const App(this.socket, {super.key});

  final RawDatagramSocket socket;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(socket),
      title: 'nx Gamepad Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}
