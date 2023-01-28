import 'package:flutter/material.dart';

import '../layouts/menu_layout.dart';

import '../pages/game_page.dart';

import 'protocol.dart';

abstract class Game {
  const Game(this.context, this.code);

  final BuildContext context;
  final List<int> code;

  int get gameUpdates;

  void openPage(StatePacket packet) {
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GamePage(this, packet),
        ),
      ),
    );
  }

  void closePage() {
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) => Navigator.of(context).popUntil(
        (route) => route.isFirst,
      ),
    );
  }

  Widget buildLayout(StatePacket packet);
}

class GameExample extends Game {
  const GameExample(super.context, super.code);

  @override
  int get gameUpdates => GameUpdate.values.length;

  @override
  Widget buildLayout(StatePacket packet) {
    switch (GameState.values[packet.state]) {
      case GameState.menu:
        return MenuLayout(packet.data);
      default:
        return ErrorWidget.withDetails(
          message: 'Received unkown state',
        );
    }
  }
}

enum GameAction {
  getState,
}

enum GameState {
  menu,
}

enum GameUpdate {
  time,
}
