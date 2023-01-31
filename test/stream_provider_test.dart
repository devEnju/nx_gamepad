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

  group('Stream Service after initialization', () {
    test(
      'Receiving null does not yield event to connection stream and does not initialize other streams',
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
      'Receiving empty datagram does not yield event to connection stream',
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
      'Receiving connection messages do not yield event to connection stream',
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

        final connection = service.controller.stream.isEmpty;

        await controller.close();
        await service.controller.sink.close();

        expect(await connection, true);
      },
    );

    test(
      'Receiving game messages do not yield event to connection stream',
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
  });

  group('Stream Service after game is set', () {
    setUp(() {
      // mock game with code [1, 1, 1]
      // startBroadcasting to set game
      // stopBroadcasting
    });

    test(
      'Receiving unknown messages do not yield event to connection stream',
      () async {
        controller.add(Datagram(
          Uint8List.fromList(<int>[0, 1, 1, 1]),
          Connection.loopback,
          Connection.port,
        ));

        controller.add(Datagram(
          Uint8List.fromList(<int>[0]),
          Connection.loopback,
          Connection.port,
        ));

        final connection = service.controller.stream.isEmpty;

        await controller.close();
        await service.controller.sink.close();

        expect(await connection, true);
      }
    );

    test(
      'Receiving valid info message yields event to connection stream',
      () async {
        controller.add(Datagram(
          Uint8List.fromList(<int>[1, 1, 1, 1]),
          Connection.loopback,
          Connection.port,
        ));

        final connection = service.controller.stream.length;

        await controller.close();
        await service.controller.sink.close();

        expect(await connection, 1);
      }
    );

    test(
      'Receiving invalid info message does not yield event to connection stream',
      () async {
        controller.add(Datagram(
          Uint8List.fromList(<int>[1]),
          Connection.loopback,
          Connection.port,
        ));

        final connection = service.controller.stream.isEmpty;

        await controller.close();
        await service.controller.sink.close();

        expect(await connection, true);
      }
    );

    test(
      'Receiving quit messages do not yield event to connection stream',
      () async {
        controller.add(Datagram(
          Uint8List.fromList(<int>[2, 1, 1, 1]),
          Connection.loopback,
          Connection.port,
        ));

        controller.add(Datagram(
          Uint8List.fromList(<int>[2]),
          Connection.loopback,
          Connection.port,
        ));

        final connection = service.controller.stream.isEmpty;

        await controller.close();
        await service.controller.sink.close();

        expect(await connection, true);
      }
    );

    test(
      'Receiving broadcast messages do not yield event to connection stream',
      () async {
        controller.add(Datagram(
          Uint8List.fromList(<int>[3, 1, 1, 1]),
          Connection.loopback,
          Connection.port,
        ));

        controller.add(Datagram(
          Uint8List.fromList(<int>[3]),
          Connection.loopback,
          Connection.port,
        ));

        final connection = service.controller.stream.isEmpty;

        await controller.close();
        await service.controller.sink.close();

        expect(await connection, true);
      }
    );

    test(
      'Receiving info messages from same address yield one event to connection stream',
      () async {
        // add 1 info message
        // addresses should have 1 entry
        // add 1 info message from same address
        // addresses should have 1 entry
        // stream should yield 1 event
      }
    );

    test(
      'Receiving info messages from unique addresses yield events to connection stream',
      () async {
        // add 3 info messages from unique addresses
        // addresses should have 3 entries
        // should yield 3 events
      }
    );

    test(
      'Receiving quit after info message from same address yield events to connection stream',
      () async {
        // add 1 info message
        // addresses should have 1 entry
        // add 1 quit message
        // addresses should be empty
        // should yield 2 events
      }
    );

    group('Stream Service after game changed', () {
      setUp(() {
        // add couple info messages from unique addresses
        // mock game with code [2, 2, 2]
        // startBroadcasting to set game
        // stopBroadcasting
      });
    });

    group('Stream Service after selecting connection', () {
      setUp(() {});

      group('Stream Service after successful selection', () {
        setUp(() {});
      });
    });
  });
}
