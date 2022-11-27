import 'dart:async';

import 'package:flutter/material.dart';

import '../layouts/menu_layout.dart';

import '../models/server_packet.dart';

import '../providers/stream_provider.dart';

import '../utils/connection.dart';
import '../utils/protocol.dart';

class GamePage extends StatefulWidget {
  const GamePage(this.initial, {super.key});

  final StatePacket initial;

  static void open(StatePacket packet) {
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) => Navigator.of(Connection.context!).push(
        MaterialPageRoute(
          builder: (context) => GamePage(packet),
        ),
      ),
    );
  }

  static void close(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) => Navigator.of(context).pop(),
    );
  }

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with WidgetsBindingObserver {
  late final StreamProvider _provider;

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
  void didChangeDependencies() {
    _provider = StreamProvider.of(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _screen ? _setTimer : _resetTimer,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        body: StreamBuilder<StatePacket>(
          initialData: widget.initial,
          stream: _provider.stream,
          builder: (context, snapshot) {
            final StatePacket packet = snapshot.data!;

            switch (packet.state) {
              case GameState.menu:
                return MenuLayout(packet.data);
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
    _provider.resetConnection();
    WidgetsBinding.instance.removeObserver(this);
    Connection.turnScreenOn();
    Connection.resetAddress();
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
    if (state) {
      _screen = await Connection.turnScreenOn() ?? _screen;
    } else {
      _screen = await Connection.turnScreenOff() ?? _screen;
    }
    setState(() {});
  }
}
