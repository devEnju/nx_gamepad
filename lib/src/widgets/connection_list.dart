import 'dart:io';

import 'package:flutter/material.dart';

import '../providers/stream_provider.dart';

class ConnectionList extends StatefulWidget {
  const ConnectionList(
    this.addresses, {
    super.key,
  });

  final Set<InternetAddress> addresses;

  @override
  State<ConnectionList> createState() => _ConnectionListState();
}

class _ConnectionListState extends State<ConnectionList> {
  late final StreamProvider _provider;

  @override
  void didChangeDependencies() {
    _provider = StreamProvider.of(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: widget.addresses.map<Widget>(_buildTextButton).toList(),
      ),
    );
  }

  Widget _buildTextButton(InternetAddress address) {
    return TextButton(
      onPressed: () => _provider.selectConnection(address),
      child: Text(address.address),
    );
  }
}
