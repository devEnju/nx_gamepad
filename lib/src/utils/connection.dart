import 'dart:io';

import 'package:flutter/services.dart';

import '../models/protocol.dart';

// const _eventChannel = EventChannel('com.marvinvogl.nx_gamepad/event');
const _methodChannel = MethodChannel('com.marvinvogl.nx_gamepad/method');

class Connection {
  static const int port = 44700;

  static final loopback = InternetAddress('127.0.0.1');
  static final broadcast = InternetAddress('255.255.255.255');

  static Future<bool?> setAddress(InternetAddress connection) {
    return _platform(
      'setAddress',
      arguments: <String, String>{
        'address': connection.address,
        'port': '$port',
      },
      substitute: true,
    );
  }

  static Future<bool?> resetAddress() => _platform('resetAddress');

  static Future<bool?> toggleScreenBrightness(bool state) {
    return state ? _platform('turnScreenOn') : _platform('turnScreenOff');
  }

  static void platformAction(ActionPacket packet) {}

  static Future<T?> _platform<T>(
    String method, {
    dynamic arguments,
    T? substitute,
  }) async {
    try {
      return await _methodChannel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return substitute;
    } catch (e) {
      rethrow;
    }
  }
}
