import 'dart:io';

import 'package:flutter/material.dart';

import '../models/game.dart';

import '../providers/stream_provider.dart';

import '../widgets/broadcast_button.dart';
import '../widgets/connection_list.dart';
import '../widgets/problem_text.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final StreamProvider _provider;

  @override
  void didChangeDependencies() {
    _provider = StreamProvider.of(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('nx Gamepad'),
        centerTitle: true,
      ),
      body: StreamBuilder<InternetAddress>(
        stream: _provider.controller.stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ProblemText(snapshot.error.toString());
          }
          return ConnectionList(_provider.addresses);
        },
      ),
      floatingActionButton: BroadcastButton(
        game: GameExample(context),
      ),
    );
  }
}
