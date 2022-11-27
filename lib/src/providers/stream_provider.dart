import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';

import '../models/server_packet.dart';

import '../services/stream_service.dart';

import '../utils/connection.dart';
import '../utils/protocol.dart';

class StreamProvider extends InheritedWidget {
  StreamProvider(
    this.socket,
    this.controller, {
    super.key,
    required super.child,
  }) {
    socket.listen(_onData);
  }

  final RawDatagramSocket socket;
  final StreamController<ConnectionPacket> controller;
  final updateControllerList = List<StreamController<List<int>>?>.filled(
    GameUpdate.values.length,
    null,
  );
  final StreamService service = StreamService();

  Stream<StatePacket> get stream => service.stateController!.stream;

  static StreamProvider of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<StreamProvider>();
    assert(result != null, 'No StreamProvider found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => false;

  void _onData(RawSocketEvent event) {
    if (event == RawSocketEvent.read) {
      final datagram = socket.receive();

      if (datagram != null && datagram.data.isNotEmpty) {
        final int message = datagram.data[0];

        if (message < 4) {
          controller.add(ConnectionPacket(datagram));
        } else if (service.connection == datagram.address) {
          final stateController = service.stateController;

          if (stateController == null) {
            if (message == Server.state.value) {
              _setupPlatform(
                () => service.onConnection!(StatePacket(datagram.data)),
              );
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

  Future<void> _setupPlatform(void Function()? onSuccess) async {
    service.stateController = StreamController<StatePacket>();

    final value = await Connection.setAddress(service.connection!);

    if (value != null && onSuccess != null) {
      onSuccess();
    }
  }
}
