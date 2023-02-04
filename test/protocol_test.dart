import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:nx_gamepad/src/models/protocol.dart';
import 'package:nx_gamepad/src/utils/connection.dart';

Datagram connectionDatagram({
  int? message,
  bool? game,
  String? text,
  InternetAddress? address,
}) {
  final data = <int>[];

  if (message != null) data.add(message);

  if (game != null) {
    game ? data.addAll([1, 1, 1]) : data.addAll([0, 0, 0]);
  }

  if (text != null) {
    data.addAll(text.codeUnits);
  }

  return Datagram(
    Uint8List.fromList(data),
    address ?? InternetAddress('192.168.0.2'),
    Connection.port,
  );
}

Datagram gameDatagram({
  int? message,
  int? value,
  InternetAddress? address,
}) {
  final data = <int>[];

  if (message != null) data.add(message);

  if (value != null) data.add(value);

  return Datagram(
    Uint8List.fromList(data),
    address ?? InternetAddress('192.168.0.2'),
    Connection.port,
  );
}

void main() {
  group('Connection Packet data needs to at least have 4 entries', () {
    test(
      'Initializing invalid packet results into empty one',
      () {
        final packet = ConnectionPacket.buffer(Datagram(
          Uint8List.fromList([0]),
          Connection.loopback,
          Connection.port,
        ));

        expect(packet.address, Connection.loopback);
        expect(packet.message, 0);
        expect(packet.code, List.empty());
        expect(packet.data, '');
        expect(packet, ConnectionPacket.empty);
      },
    );

    test(
      'Initializing valid but unknown packet',
      () {
        final packet = ConnectionPacket.buffer(Datagram(
          Uint8List.fromList([0, 0, 0, 0, ...'Hello World'.codeUnits]),
          Connection.loopback,
          Connection.port,
        ));

        expect(packet.address, Connection.loopback);
        expect(packet.message, 0);
        expect(packet.code, [0, 0, 0]);
        expect(packet.data, 'Hello World');
      },
    );

    test(
      'Initializing valid info packet',
      () {
        final packet = ConnectionPacket.buffer(Datagram(
          Uint8List.fromList([Server.info, 0, 0, 0]),
          Connection.loopback,
          Connection.port,
        ));

        expect(packet.address, Connection.loopback);
        expect(packet.message, Server.info);
        expect(packet.code, [0, 0, 0]);
        expect(packet.data, '');
      },
    );

    test(
      'Initializing valid quit packet',
      () {
        final packet = ConnectionPacket.buffer(Datagram(
          Uint8List.fromList([Server.quit, 0, 0, 0]),
          Connection.loopback,
          Connection.port,
        ));

        expect(packet.address, Connection.loopback);
        expect(packet.message, Server.quit);
        expect(packet.code, [0, 0, 0]);
        expect(packet.data, '');
      },
    );

    test(
      'Initializing valid broadcast packet',
      () {
        final packet = ConnectionPacket.buffer(Datagram(
          Uint8List.fromList([Client.broadcast, 0, 0, 0]),
          Connection.loopback,
          Connection.port,
        ));

        expect(packet.address, Connection.loopback);
        expect(packet.message, Client.broadcast);
        expect(packet.code, [0, 0, 0]);
        expect(packet.data, '');
      },
    );

    test(
      'Checking that empty packets are same instance',
      () {
        final packet = ConnectionPacket.buffer(Datagram(
          Uint8List.fromList([0]),
          Connection.loopback,
          Connection.port,
        ));

        final other = ConnectionPacket.buffer(Datagram(
          Uint8List.fromList([1]),
          Connection.loopback,
          Connection.port,
        ));

        expect(other, packet);
      },
    );

    test(
      'Checking that packet buffer is same instance',
      () {
        final packet = ConnectionPacket.buffer(Datagram(
          Uint8List.fromList([0, 0, 0, 0, ...'Hello World'.codeUnits]),
          Connection.loopback,
          Connection.port,
        ));

        final other = ConnectionPacket.buffer(Datagram(
          Uint8List.fromList([0, 1, 1, 1, ...'Hello World'.codeUnits]),
          Connection.loopback,
          Connection.port,
        ));

        expect(other, packet);
      },
    );

    test(
      'Checking that empty packet and buffer are different instances',
      () {
        final packet = ConnectionPacket.buffer(Datagram(
          Uint8List.fromList([0, 0, 0, 0, ...'Hello World'.codeUnits]),
          Connection.loopback,
          Connection.port,
        ));

        expect(ConnectionPacket.empty, isNot(packet));
      },
    );
  });

  group('Game Packet data needs to at least have 2 entries', () {
    test(
      'Initializing invalid packet results into empty one',
      () {
        final packet = GamePacket.buffer([16]);

        expect(packet.message, 0);
        expect(packet.value, 0);
        expect(packet, GamePacket.empty);
      },
    );

    test(
      'Initializing valid but unknown packet',
      () {
        final packet = GamePacket.buffer([16, 0, 1, 2, 3]);

        expect(packet.message, 16);
        expect(packet.value, 0);
      },
    );

    test(
      'Initializing valid state packet',
      () {
        final packet = GamePacket.buffer([Server.state, 0]);

        expect(packet.message, Server.state);
        expect(packet.value, 0);
      },
    );

    test(
      'Initializing valid update packet',
      () {
        final packet = GamePacket.buffer([Server.update, 0]);


        expect(packet.message, Server.update);
        expect(packet.value, 0);
      },
    );

    test(
      'Initializing valid effect packet',
      () {
        final packet = GamePacket.buffer([Server.effect, 0]);

        expect(packet.message, Server.effect);
        expect(packet.value, 0);
      },
    );

    test(
      'Checking that empty packets are same instance',
      () {
        final packet = GamePacket.buffer([4]);

        final other = GamePacket.buffer([8]);

        expect(other, packet);
      },
    );

    test(
      'Checking that packet buffer is same instance',
      () {
        final packet = GamePacket.buffer([16, 0, 1, 2, 3]);

        final other = GamePacket.buffer([16, 1, 1, 2, 3]);

        expect(other, packet);
      },
    );

    test(
      'Checking that empty packet and buffer are different instances',
      () {
        final packet = GamePacket.buffer([16, 0, 1, 2, 3]);

        expect(GamePacket.empty, isNot(packet));
      },
    );
  });
}
