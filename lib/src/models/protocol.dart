import 'dart:io';

import '../utils/connection.dart';

class ConnectionPacket {
  ConnectionPacket(Datagram datagram)
      : address = datagram.address,
        action = datagram.data[0],
        data = String.fromCharCodes(datagram.data.sublist(1));

  ConnectionPacket.problem(this.data)
      : address = Connection.loopback,
        action = 0;

  final InternetAddress address;
  final int action;
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
