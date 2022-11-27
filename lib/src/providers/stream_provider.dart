import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';

import '../models/server_packet.dart';

import '../pages/game_page.dart';

import '../services/stream_service.dart';

import '../utils/connection.dart';
import '../utils/protocol.dart';

class StreamProvider extends InheritedWidget {
  StreamProvider(
    this._socket,
    this.controller,
    this._service, {
    super.key,
    required super.child,
  }) {
    _socket.listen(_onData);
  }

  final RawDatagramSocket _socket;
  final StreamController<ConnectionPacket> controller;
  final StreamService _service;

  final updateControllerList = List<StreamController<List<int>>?>.filled(
    GameUpdate.values.length,
    null,
  );

  InternetAddress get connection => _service.connection!;
  Stream<StatePacket> get stream => _service.controller!.stream;

  static StreamProvider of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<StreamProvider>();
    assert(result != null, 'No StreamProvider found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => false;

  void _onData(RawSocketEvent event) {
    if (event == RawSocketEvent.read) {
      final datagram = _socket.receive();

      if (datagram != null && datagram.data.isNotEmpty) {
        final int message = datagram.data[0];

        if (message < 4) {
          controller.add(ConnectionPacket(datagram));
        } else if (_service.connection == datagram.address) {
          final stateController = _service.controller;

          if (stateController == null) {
            if (message == Server.state.value) {
              _setupPlatform(() => GamePage.open(StatePacket(datagram.data)));
            }
          } else if (message == Server.update.value) {
            final packet = UpdatePacket(datagram.data);
            final updateController = updateControllerList[packet.update.index];

            if (updateController != null) {
              updateController.add(packet.data);
            }
          } else {
            stateController.add(StatePacket(datagram.data));
          }
        }
      }
    }
  }

  Future<void> _setupPlatform(void Function() onSuccess) async {
    _service.controller = StreamController<StatePacket>();

    final value = await Connection.setAddress(connection);

    if (value != null) {
      onSuccess();
    }
  }

  void broadcastGamepad() {
    _socket.broadcastEnabled = true;
    _socket.send(
      <int>[Client.broadcast.value, 255, 255, 255, 255],
      InternetAddress('255.255.255.255'),
      Connection.port,
    );
    _socket.broadcastEnabled = false;
  }

  void selectConnection(InternetAddress address) {
    _service.connection = address;

    _socket.send(
      <int>[Client.state.value],
      address,
      Connection.port,
    );
  }

  void resetConnection() {
    controller.close();
    _service.controller = null;
    _service.connection = null;
  }
}
