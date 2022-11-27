import 'dart:async';
import 'dart:io';

import '../models/server_packet.dart';

class StreamService {
  StreamService({
    this.connection,
    this.controller,
  });

  InternetAddress? connection;
  StreamController<StatePacket>? controller;
}
