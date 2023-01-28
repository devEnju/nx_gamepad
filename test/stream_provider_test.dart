import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nx_gamepad/src/providers/stream_provider.dart';
import 'package:nx_gamepad/src/utils/connection.dart';

void main() {
  late StreamController<Datagram?> controller;
  late StreamService service;

  setUp(() async {
    controller = StreamController<Datagram?>();

    service = StreamService.mock(
      await RawDatagramSocket.bind(Connection.loopback, 0),
      controller.stream,
    );
  });

  group('Stream Service', () {
    test(
      'Receiving null does not yield packet to connection stream and does not initialize other streams',
      () async {
        controller.add(null);

        final connection = service.controller.stream.isEmpty;

        await controller.close();
        await service.controller.sink.close();

        expect(await connection, true);

        expect(service.state, null);
        expect(service.update, null);
      },
    );

    test(
      'Receiving an empty datagram does not yield packet to connection stream',
      () async {
        controller.add(Datagram(
          Uint8List.fromList(<int>[]),
          Connection.loopback,
          Connection.port,
        ));

        final connection = service.controller.stream.isEmpty;

        await controller.close();
        await service.controller.sink.close();

        expect(await connection, true);
      },
    );

    test(
      'Receiving message before a connection does not yield packet to connection stream',
      () async {
        controller.add(Datagram(
          Uint8List.fromList(<int>[4]),
          Connection.loopback,
          Connection.port,
        ));

        controller.add(Datagram(
          Uint8List.fromList(<int>[6]),
          Connection.loopback,
          Connection.port,
        ));

        controller.add(Datagram(
          Uint8List.fromList(<int>[8]),
          Connection.loopback,
          Connection.port,
        ));

        final connection = service.controller.stream.isEmpty;

        await controller.close();
        await service.controller.sink.close();

        expect(await connection, true);
      },
    );

    test(
      'Receiving valid message before connection, yields an event to connection stream',
      () async {
        controller.add(Datagram(
          Uint8List.fromList(<int>[0]),
          Connection.loopback,
          Connection.port,
        ));

        controller.add(Datagram(
          Uint8List.fromList(<int>[1]),
          Connection.loopback,
          Connection.port,
        ));

        controller.add(Datagram(
          Uint8List.fromList(<int>[2]),
          Connection.loopback,
          Connection.port,
        ));

        controller.add(Datagram(
          Uint8List.fromList(<int>[3]),
          Connection.loopback,
          Connection.port,
        ));

        final connection = service.controller.stream.length;

        await controller.close();
        await service.controller.sink.close();

        expect(await connection, 4);
      },
    );
  });
}
