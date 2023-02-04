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

  void startBroadcast(Game game, [void Function()? onStop]) {
    _service.startBroadcast(game, onStop);
  }

  void stopBroadcast() {
    _service.stopBroadcast();
  }

  void selectConnection(InternetAddress address, [void Function()? onChange]) {
    _service.selectConnection(address, onChange);
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
  @visibleForTesting
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

  final Set<InternetAddress> addresses = {};

  Game? _game;
  Timer? _periodic;
  Timer? _timeout;

  void Function()? _onBroadcastStop;
  void Function()? _onSelectionChange;

  InternetAddress? connection;
  StreamController<StatePacket>? state;
  List<StreamController<UpdatePacket>?>? update;

  void _onData(Datagram? event) {
    final Datagram? datagram = event;

    if (datagram != null && datagram.data.isNotEmpty) {
      final int message = datagram.data[0];

      if (message < 4) {
        assert(
          datagram.data.length >= 4,
          'received invalid packet for message $message',
        );

        handleConnectionPackets(ConnectionPacket.buffer(datagram));
      } else if (connection == datagram.address) {
        assert(
          datagram.data.length >= 2,
          'received invalid packet for message $message',
        );

        handleGamePackets(GamePacket.buffer(datagram.data));
      }
    }
  }

  @visibleForTesting
  void handleConnectionPackets(ConnectionPacket packet) {
    if (_game?.compareCode(packet.code) != null) {
      if (packet.message == Server.info) {
        _addAddress(packet.address);
      } else if (packet.message == Server.quit) {
        _removeAddress(packet.address);
      }
    }
  }

  void _addAddress(InternetAddress address) {
    if (addresses.add(address)) controller.add(address);
  }

  void _removeAddress(InternetAddress address) {
    if (connection == address) _game!.closePage();

    if (addresses.remove(address)) controller.add(address);
  }

  @visibleForTesting
  void handleGamePackets(GamePacket packet) {
    if (state == null) {
      if (packet.message == Server.state) {
        stopBroadcast();
        _timeout!.cancel();
        _setupStreams();
        setupPlatform(StatePacket(packet));
      }
    } else if (packet.message == Server.state) {
      _addStatePacket(packet);
    } else if (packet.message == Server.update) {
      _addUpdatePacket(packet);
    } else if (packet.message == Server.effect) {
      performGameEffect(packet);
    }
  }

  void _setupStreams() {
    state = StreamController<StatePacket>();
    update = List<StreamController<UpdatePacket>?>.filled(
      _game!.updates,
      null,
    );
  }

  @visibleForTesting
  Future<void> setupPlatform(StatePacket packet) async {
    final result = await Connection.setAddress(connection!);

    if (result != null) {
      _game!.openPage(packet);
    } else {
      resetConnection(reason: 'platform issue');
    }
  }

  void _addStatePacket(GamePacket packet) {
    assert(
      packet.value < _game!.states,
      'received unknown state ${packet.value}',
    );

    if (packet.value < _game!.states) {
      state!.add(StatePacket(packet));
    }
  }

  void _addUpdatePacket(GamePacket packet) {
    assert(
      packet.value < _game!.updates,
      'received unknown update ${packet.value}',
    );

    if (packet.value < _game!.updates) {
      final StreamSink<UpdatePacket>? sink = update![packet.value];

      if (sink != null) {
        sink.add(UpdatePacket(packet));
      }
    }
  }

  @visibleForTesting
  void performGameEffect(GamePacket packet) {
    Connection.gamepadAction(EffectPacket(packet));
  }

  void startBroadcast(Game game, [void Function()? onStop]) {
    if (connection == null) {
      if (_game != game) {
        addresses.clear();
      }
      _game = game;

      stopBroadcast();

      _broadcastGamepad(game.code);
      _periodic = Timer.periodic(
        const Duration(seconds: 3),
        (timer) => _broadcastGamepad(game.code),
      );
      _onBroadcastStop = onStop;
    }
  }

  void stopBroadcast() {
    _periodic?.cancel();
    _onBroadcastStop?.call();
    _onBroadcastStop = null;
  }

  void _broadcastGamepad(List<int> code) {
    _socket.broadcastEnabled = true;
    _socket.send(
      <int>[Client.broadcast, ...code],
      Connection.broadcast,
      Connection.port,
    );
    _socket.broadcastEnabled = false;
  }

  void selectConnection(InternetAddress address, [void Function()? onChange]) {
    if (connection != address) {
      connection = address;

      _timeout?.cancel();
      _onSelectionChange?.call();

      _socket.send(
        <int>[Client.action, 0],
        address,
        Connection.port,
      );

      _timeout = Timer(
        const Duration(seconds: 5),
        () => resetConnection(reason: 'no response'),
      );
      _onSelectionChange = onChange;
    }
  }

  void resetConnection({String? reason}) {
    if (reason != null) {
      addresses.remove(connection);

      controller.addError(FlutterError(reason));
    }

    connection = null;

    state?.close();
    state = null;

    for (int i = 0; i < (update?.length ?? 0); i++) {
      update![i]?.close();
      update![i] = null;
    }
    update = null;
  }

  void requestAction(Enum action, List<int> data) {
    _sendRequest(<int>[
      Client.action,
      action.index,
      ...data,
    ]);
  }

  void requestState(Enum state) {
    _sendRequest(<int>[
      Client.state,
      state.index,
    ]);
  }

  void requestUpdate(Enum update) {
    _sendRequest(<int>[
      Client.update,
      update.index,
    ]);
  }

  void _sendRequest(List<int> data) {
    final InternetAddress? address = connection;

    if (address != null) {
      _socket.send(data, address, Connection.port);
    }
  }
}
