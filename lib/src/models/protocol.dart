import 'dart:io';

import 'package:flutter/widgets.dart';

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
      return empty;
    }
    return _buffer
      .._address = datagram.address
      .._message = datagram.data[0]
      .._code = datagram.data.sublist(1, 4)
      .._data = String.fromCharCodes(datagram.data.sublist(4));
  }

  static final _buffer = ConnectionPacket._empty();

  @visibleForTesting
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
      return empty;
    }
    return _buffer
      .._message = data[0]
      .._value = data[1]
      .._data = data.sublist(2);
  }

  static final _buffer = GamePacket._empty();

  @visibleForTesting
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

class EffectPacket {
  EffectPacket(GamePacket packet)
      : effect = packet._value < GameEffect.values.length
            ? GameEffect.values[packet._value]
            : null,
        data = packet._data;

  final GameEffect? effect;
  final List<int> data;
}

class Client {
  static const int action = 1;
  static const int broadcast = 3;
  static const int state = 5;
  static const int update = 9;
}

class Server {
  static const int info = 1;
  static const int quit = 2;
  static const int state = 4;
  static const int update = 8;
  static const int effect = 12;
}
