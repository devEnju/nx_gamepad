import 'dart:io';

import 'package:flutter/material.dart';

import '../layouts/connection_layout.dart';
import '../layouts/problem_layout.dart';

import '../models/game.dart';
import '../models/protocol.dart';

import '../providers/stream_provider.dart';

import '../widgets/broadcast_button.dart';

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
            final ConnectionPacket packet = snapshot.data!;

            if (packet.action == Server.info.value) {
              _addresses.add(packet.address);
            } else if (packet.action == Server.quit.value) {
              if (_provider.connection == packet.address) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (timeStamp) => Navigator.of(context).popUntil(
                    (route) => route.isFirst,
                  ),
                );
              }
              _addresses.remove(packet.address);
            } else {
              _addresses.clear();

              return ProblemLayout(packet.data);
            }
          }
          return ConnectionLayout(_addresses);
        },
      ),
      floatingActionButton: BroadcastButton(
        game: GameExample(context, <int>[255, 255, 255]),
      ),
    );
  }
}
