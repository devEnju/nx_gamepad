import 'dart:io';

import 'game.dart';

class ConnectionPacket {
  ConnectionPacket(Datagram datagram)
      : address = datagram.address,
        message = datagram.data[0],
        code = datagram.data.sublist(1, 4),
        data = String.fromCharCodes(datagram.data.sublist(4));

  final InternetAddress address;
  final int message;
  final List<int> code;
  final String data;
}

class StatePacket {
  StatePacket(List<int> data)
      : state = data[1],
        data = data.sublist(2);

  final int state;
  final List<int> data;
}

class UpdatePacket {
  UpdatePacket(List<int> data)
      : update = data[1],
        data = data.sublist(2);

  final int update;
  final List<int> data;
}

class ActionPacket {
  ActionPacket(List<int> data)
      : action = GamepadAction.values[data[1]],
        data = data.sublist(2);

  final GamepadAction action;
  final List<int> data;
}

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
  update(6),
  action(8),
  unknown(0);

  const Server(this.value);

  final int value;
}
