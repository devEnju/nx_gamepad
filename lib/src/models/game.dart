import 'package:flutter/material.dart';

import '../layouts/menu_layout.dart';

import '../pages/game_page.dart';

import 'protocol.dart';

abstract class Game {
  const Game(this.context, this.code);

  final BuildContext context;
  final List<int> code;

  int get states;
  int get updates;

  Game? compareCode(List<int> other) {
    if (code.length != other.length) {
      return null;
    }
    for (int i = 0; i < code.length; i++) {
      if (code[i] != other[i]) return null;
    }
    return this;
  }

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

enum GamepadAction {
  rumble,
}


const List<int> _code = [255, 255, 255];

class GameExample extends Game {
  const GameExample(BuildContext context) : super(context, _code);

  @override
  int get states => GameState.values.length;

  @override
  int get updates => GameUpdate.values.length;

  @override
  Widget buildLayout(StatePacket packet) {
    switch (GameState.values[packet.state]) {
      case GameState.menu:
        return MenuLayout(packet.data);
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
