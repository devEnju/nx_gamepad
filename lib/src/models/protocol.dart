import 'dart:io';

import '../utils/connection.dart';

import 'game.dart';

class ConnectionPacket {
  ConnectionPacket._empty()
      : _address = Connection.loopback,
        _message = 0,
        _code = List.empty(),
        _data = '';

  factory ConnectionPacket.buffer(Datagram datagram) {
    if (datagram.data.length < 4) {
      assert(false, 'received invalid packet for message ${datagram.data[0]}');
      return empty;
    }
    return _buffer
      .._address = datagram.address
      .._message = datagram.data[0]
      .._code = datagram.data.sublist(1, 4)
      .._data = String.fromCharCodes(datagram.data.sublist(4));
  }

  static final _buffer = ConnectionPacket._empty();
  static final empty = ConnectionPacket._empty();

  InternetAddress _address;
  int _message;
  List<int> _code;
  String _data;

  InternetAddress get address => _address;
  int get message => _message;
  List<int> get code => _code;
  String get data => _data;
}

class GamePacket {
  GamePacket._empty()
      : _message = 0,
        _value = 0,
        _data = List.empty();

  factory GamePacket.buffer(List<int> data) {
    if (data.length < 2) {
      assert(false, 'received invalid packet for message ${data[0]}');
      return empty;
    }
    return _buffer
      .._message = data[0]
      .._value = data[1]
      .._data = data.sublist(2);
  }

  static final _buffer = GamePacket._empty();
  static final empty = GamePacket._empty();

  int _message;
  int _value;
  List<int> _data;

  int get message => _message;
  int get value => _value;
}

class StatePacket {
  StatePacket(GamePacket packet)
      : state = packet._value,
        data = packet._data;

  final int state;
  final List<int> data;
}

class UpdatePacket {
  UpdatePacket(GamePacket packet) : data = packet._data;

  final List<int> data;
}

class ActionPacket {
  ActionPacket(GamePacket packet)
      : action = packet._value < GamepadAction.values.length
            ? GamepadAction.values[packet._value]
            : null,
        data = packet._data;

  final GamepadAction? action;
  final List<int> data;
}

enum Client {
  touch(1),
  broadcast(3),
  state(5),
  update(9);

  const Client(this.value);

  final int value;
}

enum Server {
  info(1),
  quit(2),
  state(4),
  update(8),
  action(12);

  const Server(this.value);

  final int value;
}
