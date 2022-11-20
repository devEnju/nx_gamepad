
import 'package:flutter/services.dart';

class Connection {
  static const int port = 44700;

  static const eventChannel = EventChannel('com.marvinvogl.nx_gamepad/event');
  static const methodChannel = MethodChannel('com.marvinvogl.nx_gamepad/method');
}
