import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'src/app.dart';

import 'src/pages/game_page.dart';

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
      StreamService(
        socket,
        socket.map<Datagram?>(
          (event) => (event == RawSocketEvent.read) ? socket.receive() : null,
        ),
        open: GamePage.open,
      ),
      child: const App(),
    ),
  );
}
