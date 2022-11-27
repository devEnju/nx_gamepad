import 'package:flutter/material.dart';

import 'pages/home_page.dart';

import 'utils/connection.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: Connection.key,
      home: const HomePage(),
      title: 'nx Gamepad Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}
