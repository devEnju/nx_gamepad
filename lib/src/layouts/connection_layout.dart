import 'dart:io';

import 'package:flutter/material.dart';

import '../providers/stream_provider.dart';

class ConnectionLayout extends StatefulWidget {
  const ConnectionLayout(
    this.addresses, {
    super.key,
  });

  final Set<InternetAddress> addresses;

  @override
  State<ConnectionLayout> createState() => _ConnectionLayoutState();
}

class _ConnectionLayoutState extends State<ConnectionLayout> {
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
