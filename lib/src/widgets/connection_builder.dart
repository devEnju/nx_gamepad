import 'dart:io';

import 'package:flutter/material.dart';

import '../models/protocol.dart';

import '../providers/stream_provider.dart';

class ConnectionBuilder extends StatefulWidget {
  const ConnectionBuilder({super.key, required this.builder});

  final Widget Function(
    BuildContext context,
    Set<InternetAddress> addresses,
    String? problem,
  ) builder;

  @override
  State<ConnectionBuilder> createState() => _ConnectionBuilderState();
}

class _ConnectionBuilderState extends State<ConnectionBuilder> {
  final Set<InternetAddress> _addresses = {};

  late final StreamProvider _provider;

  @override
  void didChangeDependencies() {
    _provider = StreamProvider.of(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectionPacket>(
      stream: _provider.controller.stream,
      builder: (context, snapshot) {
        final problem = snapshot.hasData ? _onData(snapshot.data!) : null;

        return widget.builder(context, _addresses, problem);
      },
    );
  }

  String? _onData(ConnectionPacket packet) {
    if (packet.action == Server.info.value) {
      _addresses.add(packet.address);
    } else if (packet.action == Server.quit.value) {
      if (_provider.connection == packet.address) _closePage();

      _addresses.remove(packet.address);
    } else {
      _addresses.clear();

      return packet.data;
    }
    return null;
  }

  void _closePage() {
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) => Navigator.of(context).popUntil(
        (route) => route.isFirst,
      ),
    );
  }
}
