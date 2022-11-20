import 'dart:io';

import 'package:flutter/material.dart';

class MenuLayout extends StatelessWidget {
  const MenuLayout(
    this.socket,
    this.address,
    this.data, {
    super.key,
  });

  final RawDatagramSocket socket;
  final InternetAddress address;
  final List<int> data;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Build the user interface with the received data.')
    );
  }
}
