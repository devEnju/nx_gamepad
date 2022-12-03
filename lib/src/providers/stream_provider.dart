import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';

import '../models/protocol.dart';

import '../utils/connection.dart';

class StreamProvider extends InheritedWidget {
  const StreamProvider(
    this._service, {
    super.key,
    required super.child,
  });

  final StreamService _service;

  StreamController<ConnectionPacket> get controller => _service.controller;

  InternetAddress? get connection => _service.connection;
  Stream<StatePacket>? get stream => _service.state?.stream;

  Stream<UpdatePacket>? operator [](int i) => _service.update[i]?.stream;

  static StreamProvider of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<StreamProvider>();
    assert(result != null, 'No StreamProvider found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => false;

  void broadcastGamepad(List<int> code) {
    _service.broadcastGamepad(code);
  }

  void selectConnection(InternetAddress address) {
    _service.selectConnection(address);
  }

  void resetConnection() {
    _service.resetConnection();
  }

  void requestAction(GameAction action, List<int> data) {
    _service.requestAction(action, data);
  }

  void requestState(GameState state) {
    _service.requestState(state);
  }

  void requestUpdate(GameUpdate update) {
    _service.requestUpdate(update);
  }
}

class StreamService {
  StreamService(
    this._socket,
    this._stream, {
    required this.open,
  }) {
    _stream.listen(_onData);
  }

  final RawDatagramSocket _socket;
  final Stream<Datagram?> _stream;

  final controller = StreamController<ConnectionPacket>();

  final void Function(StatePacket packet) open;

  final update = List<StreamController<UpdatePacket>?>.filled(
    GameUpdate.values.length,
    null,
  );

  InternetAddress? connection;
  StreamController<StatePacket>? state;

  void _onData(Datagram? event) {
    final datagram = event;

    if (datagram != null && datagram.data.isNotEmpty) {
      final message = datagram.data[0];

      if (message < 4) {
        controller.add(ConnectionPacket(datagram));
      } else if (connection == datagram.address) {
        final stateController = state;

        if (stateController == null) {
          if (message == Server.state.value) {
            _setupPlatform(() => open(StatePacket(datagram.data)));
          }
        } else if (message == Server.update.value) {
          final packet = UpdatePacket(datagram.data);
          final updateController = update[packet.update.index];

          if (updateController != null) {
            updateController.add(packet);
          }
        } else {
          stateController.add(StatePacket(datagram.data));
        }
      }
    }
  }

  Future<void> _setupPlatform(void Function() onSuccess) async {
    state = StreamController<StatePacket>();

    final result = await Connection.setAddress(connection!);

    if (result != null) {
      onSuccess();
    } else {
      controller.add(ConnectionPacket.problem('platform issue'));
      resetConnection();
    }
  }

  void broadcastGamepad(List<int> code) async {
    _socket.broadcastEnabled = true;
    _socket.send(
      <int>[Client.broadcast.value, ...code],
      Connection.broadcast,
      Connection.port,
    );
    _socket.broadcastEnabled = false;
  }

  void selectConnection(InternetAddress address) async {
    connection = address;

    _socket.send(
      <int>[Client.action.value, GameAction.getState.index],
      address,
      Connection.port,
    );

    // timer to reset connection if there is no response
    // controller.add(ConnectionPacket.problem('no response'));
    // connection = null;
  }

  void resetConnection() {
    connection = null;

    state?.close();
    state = null;

    for (int i = 0; i < update.length; i++) {
      update[i]?.close();
      update[i] = null;
    }
  }

  void requestAction(GameAction action, List<int> data) {
    _sendRequest(<int>[
      Client.action.value,
      action.index,
      ...data,
    ]);
  }

  void requestState(GameState state) {
    _sendRequest(<int>[
      Client.state.value,
      state.index,
    ]);
  }

  void requestUpdate(GameUpdate update) {
    _sendRequest(<int>[
      Client.update.value,
      update.index,
    ]);
  }

  void _sendRequest(List<int> data) async {
    final address = connection;

    if (address != null) {
      _socket.send(
        data,
        address,
        Connection.port,
      );
    }
  }
}
