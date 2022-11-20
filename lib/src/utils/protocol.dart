enum Client {
  action(1),
  broadcast(3),
  state(5),
  update(7);

  const Client(this.value);

  final int value;
}

enum Server {
  info(1),
  quit(2),
  state(4),
  update(6);

  const Server(this.value);

  final int value;
}

enum GameState {
  menu,
}

enum GameAction {
  namedAction,
}

enum GameUpdate {
  namedUpdate,
}
