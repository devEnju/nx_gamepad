
import 'dart:io';

import 'package:flutter/services.dart';


// const _eventChannel = EventChannel('com.marvinvogl.nx_gamepad/event');
const _methodChannel = MethodChannel('com.marvinvogl.nx_gamepad/method');

class Connection {
  static const int port = 44700;

  static Future<bool?> setAddress(InternetAddress connection) async {
    if (Platform.isWindows || Platform.isMacOS) {
      return true;
    }
    return _methodChannel.invokeMethod<bool>(
      'setAddress',
      <String, String>{
        'address': connection.address,
        'port': '$port',
      },
    );
  }

  static Future<bool?> resetAddress() async {
    if (Platform.isWindows || Platform.isMacOS) {
      return true;
    }
    return _methodChannel.invokeMethod<bool>('resetAddress');
  }

  static Future<bool?> turnScreenOn() async {
    if (Platform.isWindows || Platform.isMacOS) {
      return true;
    }
    return _methodChannel.invokeMethod<bool>('turnScreenOn');
  }

  static Future<bool?> turnScreenOff() async {
    if (Platform.isWindows || Platform.isMacOS) {
      return true;
    }
    return _methodChannel.invokeMethod<bool>('turnScreenOff');
  }
}
