import 'dart:async';

import 'package:flutter/material.dart';

import '../models/game.dart';
import '../models/protocol.dart';

import '../providers/stream_provider.dart';

import '../utils/connection.dart';

class GamePage extends StatefulWidget {
  const GamePage(this.game, this.initial, {super.key, this.duration});

  final Game game;
  final StatePacket initial;
  final Duration? duration;

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
      widget.duration!,
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
            if (snapshot.hasData) {
              widget.game.buildLayout(snapshot.data!);
            }
            return ErrorWidget.withDetails(
              message: 'Stream is null',
            );
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
    Connection.toggleScreenBrightness(true);
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
    _screen = await Connection.toggleScreenBrightness(state) ?? _screen;
    setState(() {});
  }
}
