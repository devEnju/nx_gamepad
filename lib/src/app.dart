import 'package:flutter/material.dart';

import 'pages/home_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  static final GlobalKey<NavigatorState> _key = GlobalKey<NavigatorState>();

  static BuildContext? get context => _key.currentContext; 

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _key,
      home: const HomePage(),
      title: 'nx Gamepad Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}
