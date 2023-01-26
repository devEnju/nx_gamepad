import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';

import '../models/protocol.dart';

import '../pages/game_page.dart';

import '../utils/connection.dart';

class StreamProvider extends InheritedWidget {
  const StreamProvider(
    this._service, {
    super.key,
    required super.child,
  });

  final StreamService _service;

  StreamController<ConnectionPacket> get controller => _service.controller;
  Stream<bool> get broadcast => _service.broadcast.stream;

  InternetAddress? get connection => _service.connection;
  Stream<StatePacket>? get stream => _service.state?.stream;

  Stream<UpdatePacket>? operator [](int i) => _service.update?[i]?.stream;

  static StreamProvider of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<StreamProvider>();
    assert(result != null, 'No StreamProvider found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => false;

  void startBroadcast(List<int> code) {
    _service.startBroadcast(code);
  }

  void stopBroadcast() {
    _service.stopBroadcast();
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
  StreamService.mock(
    this._socket,
    this._stream, {
    required this.open,
  }) {
    _stream.listen(_onData);
  }

  factory StreamService(RawDatagramSocket socket) {
    return StreamService.mock(
      socket,
      socket.map<Datagram?>(
        (event) => (event == RawSocketEvent.read) ? socket.receive() : null,
      ),
      open: GamePage.open,
    );
  }

  final RawDatagramSocket _socket;
  final Stream<Datagram?> _stream;

  final controller = StreamController<ConnectionPacket>();
  final broadcast = StreamController<bool>();

  final void Function(StatePacket packet) open;

  InternetAddress? connection;
  StreamController<StatePacket>? state;
  List<StreamController<UpdatePacket>?>? update;

  late Timer _periodic;
  late Timer _timeout;

  void _onData(Datagram? event) {
    final datagram = event;

    if (datagram != null && datagram.data.isNotEmpty) {
      final message = datagram.data[0];

      if (message < 4) {
        _addConnectionPacket(ConnectionPacket(datagram));
      } else if (connection == datagram.address) {
        _handleOtherPackets(message, datagram.data);
      }
    }
  }

  void _addConnectionPacket(ConnectionPacket packet) {
    controller.add(packet);
  }

  void _handleOtherPackets(int message, List<int> data) {
    final StreamController<StatePacket>? controller = state;

    if (controller == null) {
      if (message == Server.state.value) {
        stopBroadcast();
        _timeout.cancel();
        _setupPlatform(() => open(StatePacket(data)));
      }
    } else if (message == Server.update.value) {
      _addUpdatePacket(UpdatePacket(data));
    } else {
      _addStatePacket(StatePacket(data));
    }
  }

  Future<void> _setupPlatform(void Function() onSuccess) async {
    state = StreamController<StatePacket>();
    update = List<StreamController<UpdatePacket>?>.filled(
      GameUpdate.values.length,
      null,
    );

    final result = await Connection.setAddress(connection!);

    if (result != null) {
      onSuccess();
    } else {
      controller.add(ConnectionPacket.problem('platform issue'));
      resetConnection();
    }
  }

  void _addUpdatePacket(UpdatePacket packet) {
    final StreamSink<UpdatePacket>? sink = update![packet.update.index];

    if (sink != null) {
      sink.add(packet);
    }
  }

  void _addStatePacket(StatePacket packet) {
    state!.add(packet);
  }

  void startBroadcast(List<int> code) {
    _broadcastGamepad(code);
    _periodic = Timer.periodic(
      const Duration(seconds: 3),
      (timer) => _broadcastGamepad(code),
    );
    broadcast.add(true);
  }

  void stopBroadcast() {
    _periodic.cancel();
    broadcast.add(false);
  }

  void _broadcastGamepad(List<int> code) {
    _socket.broadcastEnabled = true;
    _socket.send(
      <int>[Client.broadcast.value, ...code],
      Connection.broadcast,
      Connection.port,
    );
    _socket.broadcastEnabled = false;
  }

  void selectConnection(InternetAddress address) {
    connection = address;

    _socket.send(
      <int>[Client.action.value, GameAction.getState.index],
      address,
      Connection.port,
    );

    _timeout = Timer(const Duration(seconds: 3), () {
      controller.add(ConnectionPacket.problem('no response'));
      connection = null;
    });
  }

  void resetConnection() {
    connection = null;

    state?.close();
    state = null;

    for (int i = 0; i < (update?.length ?? 0); i++) {
      update![i]?.close();
      update![i] = null;
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

  void _sendRequest(List<int> data) {
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
