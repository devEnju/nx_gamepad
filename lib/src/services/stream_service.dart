import 'dart:async';
import 'dart:io';

import '../models/server_packet.dart';

class StreamService {

  InternetAddress? connection;
  StreamController<StatePacket>? stateController;

  void Function(StatePacket packet)? onConnection;

}