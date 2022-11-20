import 'dart:io';

import 'package:flutter/material.dart';

class ConnectionLayout extends StatelessWidget {
  const ConnectionLayout(
    this.addresses,
    this.onSelection, {
    super.key,
  });

  final Set<InternetAddress> addresses;
  final void Function(InternetAddress) onSelection;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: addresses.map<Widget>(_buildTextButton).toList(),
      ),
    );
  }

  Widget _buildTextButton(InternetAddress address) {
    return TextButton(
      onPressed: () => onSelection(address),
      child: Text(address.address),
    );
  }
}
