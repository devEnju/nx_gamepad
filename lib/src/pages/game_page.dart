import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../layouts/menu_layout.dart';

import '../utils/connection.dart';
import '../utils/protocol.dart';

class GamePage extends StatefulWidget {
  const GamePage(
    this.socket,
    this.address,
    this.initial,
    this.controller,
    this.onDispose, {
    super.key,
  });

  final RawDatagramSocket socket;
  final InternetAddress address;
  final Uint8List initial;
  final StreamController<Uint8List> controller;
  final void Function() onDispose;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with WidgetsBindingObserver {
  late bool _screen;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _initTimer();
  }

  void _initTimer() {
    _screen = true;
    _timer = Timer(
      const Duration(seconds: 10),
      () => _toggleScreenBrightness(false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTapDown: _screen ? _setTimer : _resetTimer,
        behavior: HitTestBehavior.opaque,
        child: StreamBuilder<Uint8List>(
          initialData: widget.initial,
          stream: widget.controller.stream,
          builder: (context, snapshot) {
            final received = snapshot.data!;

            final message = received[1];
            final data = received.sublist(2);

            switch (GameState.values[message]) {
              case GameState.menu:
                return MenuLayout(
                  widget.socket,
                  widget.address,
                  data,
                );
              default:
                return ErrorWidget.withDetails(
                  message: 'Received unkown state.',
                );
            }
          },
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.inactive) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    Connection.methodChannel.invokeMethod<bool>('turnScreenOn');
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.close();
    widget.onDispose();
    super.dispose();
  }

  void _setTimer(TapDownDetails details) {
    _timer.cancel();
    _initTimer();
  }

  void _resetTimer(TapDownDetails details) {
    _toggleScreenBrightness(true);

    _setTimer(details);
  }

  Future<void> _toggleScreenBrightness(bool state) async {
    const channel = Connection.methodChannel;

    if (state) {
      _screen = await channel.invokeMethod<bool>('turnScreenOn') ?? _screen;
    } else {
      _screen = await channel.invokeMethod<bool>('turnScreenOff') ?? _screen;
    }
    setState(() {});
  }
}
