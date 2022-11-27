import 'dart:io';

import 'package:flutter/material.dart';

import '../providers/stream_provider.dart';

import '../utils/connection.dart';
import '../utils/protocol.dart';

class ConnectionLayout extends StatelessWidget {
  const ConnectionLayout(
    this.addresses, {
    super.key,
  });

  final Set<InternetAddress> addresses;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: addresses.map<Widget>((address) => _buildTextButton(context, address)).toList(),
      ),
    );
  }

  Widget _buildTextButton(BuildContext context, InternetAddress address) {
    return TextButton(
      onPressed: () => _selectConnection(context, address),
      child: Text(address.address),
    );
  }

  void _selectConnection(BuildContext context, InternetAddress address) {
    final provider = StreamProvider.of(context);
    provider.service.connection = address;

    provider.socket.send(
      <int>[Client.state.value, GameState.menu.index],
      address,
      Connection.port,
    );
  }
}
