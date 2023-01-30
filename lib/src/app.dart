import 'package:flutter/material.dart';

import 'pages/home_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomePage(),
      title: 'nx Gamepad Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}
