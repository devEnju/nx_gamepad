import 'package:flutter/material.dart';

import '../models/game.dart';

import '../widgets/broadcast_button.dart';
import '../widgets/connection_builder.dart';
import '../widgets/connection_list.dart';
import '../widgets/problem_text.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('nx Gamepad'),
        centerTitle: true,
      ),
      body: ConnectionBuilder(
        builder: (context, addresses, problem) {
          if (problem != null) {
            return ProblemText(problem);
          }
          return ConnectionList(addresses);
        },
      ),
      floatingActionButton: BroadcastButton(
        game: GameExample(
          context,
          <int>[255, 255, 255],
        ),
      ),
    );
  }
}
