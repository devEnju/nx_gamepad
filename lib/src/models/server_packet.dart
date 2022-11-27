import 'dart:io';

import '../utils/protocol.dart';

class ConnectionPacket {
  ConnectionPacket(Datagram datagram)
      : address = datagram.address,
        action = datagram.data[0],
        data = datagram.data.sublist(1);

  final InternetAddress address;
  final int action;
  final List<int> data;
}

class StatePacket {
  StatePacket(List<int> data)
      : state = GameState.values[data[1]],
        data = data.sublist(2);

  final GameState state;
  final List<int> data;
}

class UpdatePacket {
  UpdatePacket(List<int> data)
      : update = GameUpdate.values[data[1]],
        data = data.sublist(2);

  final GameUpdate update;
  final List<int> data;
}
