import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/app.dart';

import 'src/providers/stream_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SystemChrome.setPreferredOrientations(
    <DeviceOrientation>[DeviceOrientation.landscapeLeft],
  );

  final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

  runApp(
    StreamProvider(
      socket,
      StreamController(),
      child: const App(),
    ),
  );
}
