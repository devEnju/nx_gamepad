import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';

import '../models/game.dart';
import '../models/protocol.dart';

import '../utils/connection.dart';

class StreamProvider extends InheritedWidget {
  const StreamProvider(
    this._service, {
    super.key,
    required super.child,
  });

  final StreamService _service;

  StreamController<InternetAddress> get controller => _service.controller;
  Stream<bool> get broadcast => _service.broadcast.stream;
  Set<InternetAddress> get addresses => _service.addresses;

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

  void startBroadcast(Game game) {
    _service.startBroadcast(game);
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

  void requestAction(Enum action, List<int> data) {
    _service.requestAction(action, data);
  }

  void requestState(Enum state) {
    _service.requestState(state);
  }

  void requestUpdate(Enum update) {
    _service.requestUpdate(update);
  }
}

class StreamService {
  StreamService.mock(
    this._socket,
    this._stream,
  ) {
    _stream.listen(_onData);
  }

  factory StreamService(RawDatagramSocket socket) {
    return StreamService.mock(
      socket,
      socket.map<Datagram?>(
        (event) => (event == RawSocketEvent.read) ? socket.receive() : null,
      ),
    );
  }

  final RawDatagramSocket _socket;
  final Stream<Datagram?> _stream;

  final controller = StreamController<InternetAddress>();
  final broadcast = StreamController<bool>();

  final Set<InternetAddress> addresses = {};

  Game? _game;

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
        _handleConnectionPackets(ConnectionPacket(datagram));
      } else if (connection == datagram.address) {
        _handleGamePackets(message, datagram.data);
      }
    }
  }

  void _handleConnectionPackets(ConnectionPacket packet) {
    if (packet.action == Server.info.value) {
      if (addresses.add(packet.address)) controller.add(packet.address);
    } else if (packet.action == Server.quit.value) {
      if (connection == packet.address) _game?.closePage();

      if (addresses.remove(packet.address)) controller.add(packet.address);
    }
  }

  void _handleGamePackets(int message, List<int> data) {
    final StreamController<StatePacket>? controller = state;

    if (controller == null) {
      if (message == Server.state.value) {
        stopBroadcast();
        _timeout.cancel();
        _setupPlatform(StatePacket(data));
      }
    } else if (message == Server.update.value) {
      _addUpdatePacket(UpdatePacket(data));
    } else {
      _addStatePacket(StatePacket(data));
    }
  }

  Future<void> _setupPlatform(StatePacket packet) async {
    state = StreamController<StatePacket>();
    update = List<StreamController<UpdatePacket>?>.filled(
      _game?.gameUpdates ?? 0,
      null,
    );

    final result = await Connection.setAddress(connection!);

    if (result != null) {
      _game?.openPage(packet);
    } else {
      resetConnection(reason: 'platform issue');
    }
  }

  void _addUpdatePacket(UpdatePacket packet) {
    final StreamSink<UpdatePacket>? sink = update![packet.update];

    if (sink != null) {
      sink.add(packet);
    }
  }

  void _addStatePacket(StatePacket packet) {
    state!.add(packet);
  }

  // TODO stop broadcast in start function if it is already broadcasting
  // only one widget should be able to subscribe to a broadcast at a time
  void startBroadcast(Game game) {
    if (connection == null) {
      _game = game;

      _broadcastGamepad(game.code);
      _periodic = Timer.periodic(
        const Duration(seconds: 3),
        (timer) => _broadcastGamepad(game.code),
      );
      broadcast.add(true);
    }
  }

  void stopBroadcast() {
    if (_game != null) {
      _periodic.cancel();
      broadcast.add(false);
    }
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

  // TODO maybe let user be able to choose another connection before timeout
  void selectConnection(InternetAddress address) {
    if (connection == null) {          
      connection = address;

      _socket.send(
        <int>[Client.action.value, 0],
        address,
        Connection.port,
      );

      _timeout = Timer(
        const Duration(seconds: 3),
        () => resetConnection(reason: 'no response'),
      );
    }
  }

  void resetConnection({String? reason}) {
    if (reason != null) {
      addresses.remove(connection);

      controller.addError(FlutterError(reason));
    }

    _game = null;

    connection = null;

    state?.close();
    state = null;

    for (int i = 0; i < (update?.length ?? 0); i++) {
      update![i]?.close();
      update![i] = null;
    }
  }

  void requestAction(Enum action, List<int> data) {
    _sendRequest(<int>[
      Client.action.value,
      action.index,
      ...data,
    ]);
  }

  void requestState(Enum state) {
    _sendRequest(<int>[
      Client.state.value,
      state.index,
    ]);
  }

  void requestUpdate(Enum update) {
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
