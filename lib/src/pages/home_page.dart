import 'dart:io';

import 'package:flutter/material.dart';

import '../layouts/connection_layout.dart';

import '../models/server_packet.dart';

import '../pages/game_page.dart';

import '../providers/stream_provider.dart';

import '../utils/protocol.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Set<InternetAddress> _addresses = {};

  late final StreamProvider _provider;

  @override
  void didChangeDependencies() {
    _provider = StreamProvider.of(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('nx Gamepad'),
        centerTitle: true,
      ),
      body: StreamBuilder<ConnectionPacket>(
        stream: _provider.controller.stream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final packet = snapshot.data!;

            if (packet.action == Server.info.value) {
              _addresses.add(packet.address);
            } else if (packet.action == Server.quit.value) {
              if (_provider.connection == packet.address) {
                GamePage.close(context);
              }
              _addresses.remove(packet.address);
            }
          }
          return ConnectionLayout(_addresses);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _provider.broadcastGamepad(),
        child: const Icon(Icons.broadcast_on_home),
      ),
    );
  }
}
