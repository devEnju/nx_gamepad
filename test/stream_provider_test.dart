import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:nx_gamepad/src/models/protocol.dart';
import 'package:nx_gamepad/src/providers/stream_provider.dart';
import 'package:nx_gamepad/src/utils/connection.dart';

import 'game_test.dart';
import 'protocol_test.dart';

class MockStreamService extends StreamService {
  MockStreamService(
    RawDatagramSocket socket,
    Stream<Datagram?> stream,
  ) : super.mock(socket, stream);

  @override
  Future<void> setupPlatform(StatePacket packet) async {}

  @override
  void performGameEffect(GamePacket packet) {}
}

void main() {
  late StreamController<Datagram?> controller;
  late MockStreamService service;
  late MockGame game;

  setUp(() async {
    controller = StreamController<Datagram?>();

    service = MockStreamService(
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
        controller.add(connectionDatagram());

        final connection = service.controller.stream.isEmpty;

        await controller.close();
        await service.controller.sink.close();

        expect(await connection, true);
      },
    );

    test(
      'Receiving valid connection packets do not yield event to connection stream',
      () async {
        controller.add(connectionDatagram(
          message: 0,
          game: false,
        ));

        controller.add(connectionDatagram(
          message: Server.info,
          game: false,
        ));

        controller.add(connectionDatagram(
          message: Server.quit,
          game: false,
        ));

        controller.add(connectionDatagram(
          message: Client.broadcast,
          game: false,
        ));

        final connection = service.controller.stream.isEmpty;

        await controller.close();
        await service.controller.sink.close();

        expect(await connection, true);
      },
    );

    test(
      'Receiving valid game packets do not yield event to connection stream',
      () async {
        controller.add(gameDatagram(
          message: Server.state,
          value: 0,
        ));

        controller.add(gameDatagram(
          message: Server.update,
          value: 0,
        ));

        controller.add(gameDatagram(
          message: Server.effect,
          value: 0,
        ));

        controller.add(gameDatagram(
          message: 16,
          value: 0,
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
      game = MockGame([1, 1, 1]);

      service.startBroadcast(game);
      service.stopBroadcast();
    });

    test(
      'Receiving valid but unknown connection packet does not yield event to connection stream',
      () async {
        controller.add(connectionDatagram(
          message: 0,
          game: true,
        ));

        final connection = service.controller.stream.isEmpty;

        await controller.close();
        await service.controller.sink.close();

        expect(await connection, true);
      },
    );

    test(
      'Receiving valid info connection packet yields event to connection stream',
      () async {
        controller.add(connectionDatagram(
          message: Server.info,
          game: true,
        ));

        final connection = service.controller.stream.length;

        await controller.close();
        await service.controller.sink.close();

        expect(await connection, 1);
      },
    );

    test(
      'Receiving valid quit connection packet does not yield event to connection stream',
      () async {
        controller.add(connectionDatagram(
          message: Server.quit,
          game: true,
        ));

        final connection = service.controller.stream.isEmpty;

        await controller.close();
        await service.controller.sink.close();

        expect(await connection, true);
      },
    );

    test(
      'Receiving valid broadcast connection packet does not yield event to connection stream',
      () async {
        controller.add(connectionDatagram(
          message: Client.broadcast,
          game: true,
        ));

        final connection = service.controller.stream.isEmpty;

        await controller.close();
        await service.controller.sink.close();

        expect(await connection, true);
      },
    );

    test(
      'Receiving info connection packets from same address yield one event to connection stream',
      () async {
        controller.add(connectionDatagram(
          message: Server.info,
          game: true,
        ));

        controller.add(connectionDatagram(
          message: Server.info,
          game: true,
        ));

        final connection = service.controller.stream.length;

        await controller.close();
        await service.controller.sink.close();

        expect(service.addresses.length, 1);

        expect(await connection, 1);
      },
    );

    test(
      'Receiving info connection packets from unique addresses yield events to connection stream',
      () async {
        controller.add(connectionDatagram(
          message: Server.info,
          game: true,
          address: InternetAddress('192.168.0.3'),
        ));

        controller.add(connectionDatagram(
          message: Server.info,
          game: true,
          address: InternetAddress('192.168.0.4'),
        ));

        controller.add(connectionDatagram(
          message: Server.info,
          game: true,
          address: InternetAddress('192.168.0.5'),
        ));

        final connection = service.controller.stream.length;

        await controller.close();
        await service.controller.sink.close();

        expect(service.addresses.length, 3);

        expect(await connection, 3);
      },
    );

    test(
      'Receiving quit after info connection packet from same address yield events to connection stream',
      () async {
        controller.add(connectionDatagram(
          message: Server.info,
          game: true,
        ));

        controller.add(connectionDatagram(
          message: Server.quit,
          game: true,
        ));

        final connection = service.controller.stream.length;

        await controller.close();
        await service.controller.sink.close();

        expect(service.addresses.length, 0);

        expect(await connection, 2);
      },
    );

    test(
      'Receiving valid connection packets but from other game do not yield event to connection stream',
      () async {
        controller.add(connectionDatagram(
          message: Server.info,
          game: false,
        ));

        controller.add(connectionDatagram(
          message: Server.quit,
          game: false,
        ));

        final connection = service.controller.stream.isEmpty;

        await controller.close();
        await service.controller.sink.close();

        expect(await connection, true);
      },
    );

    test(
      'Handling empty connection packet does not yield event to connection stream',
      () async {
        service.handleConnectionPackets(ConnectionPacket.empty);

        final connection = service.controller.stream.isEmpty;

        await controller.close();
        await service.controller.sink.close();

        expect(await connection, true);
      },
    );

    test(
      'Changing game resets addresses',
      () async {
        controller.add(connectionDatagram(
          message: Server.info,
          game: true,
          address: InternetAddress('192.168.0.3'),
        ));

        controller.add(connectionDatagram(
          message: Server.info,
          game: true,
          address: InternetAddress('192.168.0.4'),
        ));

        controller.add(connectionDatagram(
          message: Server.info,
          game: true,
          address: InternetAddress('192.168.0.5'),
        ));

        final connection = service.controller.stream.length;

        await controller.close();
        await service.controller.sink.close();

        final game = MockGame([0, 0, 0]);

        service.startBroadcast(game);
        service.stopBroadcast();

        expect(service.addresses.length, 0);

        expect(await connection, 3);
      },
    );

    group('Stream Service after successful connection', () {
      setUp(() {
        service.handleConnectionPackets(
          ConnectionPacket.buffer(connectionDatagram(
            message: Server.info,
            game: true,
          )),
        );
        service.selectConnection(InternetAddress('192.168.0.2'));
        service.handleGamePackets(GamePacket.buffer([Server.state, 0]));
      });

      test(
        'Receiving null does not yield event to any stream',
        () async {
          controller.add(null);

          final connection = service.controller.stream.length;
          final state = service.state!.stream.isEmpty;

          final update = service.update![0];

          await controller.close();
          await service.controller.sink.close();
          await service.state!.sink.close();

          expect(await connection, 1);
          expect(await state, true);

          expect(update, null);
        },
      );

      test(
        'Receiving valid game packets do not yield event to connection but state stream',
        () async {
          controller.add(gameDatagram(
            message: Server.state,
            value: 0,
          ));

          controller.add(gameDatagram(
            message: Server.update,
            value: 0,
          ));

          controller.add(gameDatagram(
            message: Server.effect,
            value: 0,
          ));

          controller.add(gameDatagram(
            message: 16,
            value: 0,
          ));

          final connection = service.controller.stream.length;
          final state = service.state!.stream.length;

          await controller.close();
          await service.controller.sink.close();
          await service.state!.sink.close();

          expect(await connection, 1);
          expect(await state, 1);
        },
      );

      test(
        'Receiving valid state packets yield events to state stream',
        () async {
          controller.add(gameDatagram(
            message: Server.state,
            value: 0,
          ));

          controller.add(gameDatagram(
            message: Server.state,
            value: 0,
          ));

          controller.add(gameDatagram(
            message: Server.state,
            value: 0,
          ));

          controller.add(gameDatagram(
            message: Server.state,
            value: 0,
          ));

          final connection = service.controller.stream.isEmpty;
          final state = service.state!.stream.length;

          await controller.close();
          await service.controller.sink.close();
          await service.state!.sink.close();

          await connection;
          expect(await state, 4);
        },
      );

      test(
        'Receiving valid state packets from different address does not yield event to state stream',
        () async {
          controller.add(gameDatagram(
            message: Server.state,
            value: 0,
            address: InternetAddress('192.168.0.3'),
          ));

          controller.add(gameDatagram(
            message: Server.state,
            value: 0,
            address: InternetAddress('192.168.0.4'),
          ));

          controller.add(gameDatagram(
            message: Server.state,
            value: 0,
            address: InternetAddress('192.168.0.5'),
          ));

          final connection = service.controller.stream.isEmpty;
          final state = service.state!.stream.isEmpty;

          await controller.close();
          await service.controller.sink.close();
          await service.state!.sink.close();

          await connection;
          expect(await state, true);
        },
      );

      test(
        'Handling empty game packet does not yield event to game streams',
        () async {
          service.handleGamePackets(GamePacket.empty);

          final connection = service.controller.stream.isEmpty;
          final state = service.state!.stream.isEmpty;

          await controller.close();
          await service.controller.sink.close();
          await service.state!.sink.close();

          await connection;
          expect(await state, true);
        },
      );

      test(
        'Handling game packet with unknown state does not yield event to state stream but asserts',
        () async {
          expect(
            () {
              service.handleGamePackets(GamePacket.buffer([Server.state, 4]));
            },
            throwsAssertionError,
          );

          final connection = service.controller.stream.isEmpty;
          final state = service.state!.stream.isEmpty;

          await controller.close();
          await service.controller.sink.close();
          await service.state!.sink.close();

          await connection;
          await state;
        },
      );

      test(
        'Handling game packet with unknown update does not yield event to update stream but asserts',
        () async {
          expect(
            () {
              service.handleGamePackets(GamePacket.buffer([Server.update, 2]));
            },
            throwsAssertionError,
          );

          final connection = service.controller.stream.isEmpty;
          final state = service.state!.stream.isEmpty;

          await controller.close();
          await service.controller.sink.close();
          await service.state!.sink.close();

          await connection;
          await state;
        },
      );

      test(
        'Resetting connection keeps selected address in addresses',
        () async {
          final address = InternetAddress('192.168.0.2');

          expect(service.connection, address);
          expect(service.addresses.contains(address), true);

          service.resetConnection();

          final connection = service.controller.stream.isEmpty;

          await controller.close();
          await service.controller.sink.close();

          expect(service.connection, null);
          expect(service.addresses.contains(address), true);

          await connection;

          expect(service.state, null);
          expect(service.update, null);
        },
      );
    });
  });
}
