import 'package:flutter/material.dart';

import '../models/game.dart';

import '../providers/stream_provider.dart';

class BroadcastButton extends StatefulWidget {
  const BroadcastButton({super.key, required this.game});

  final Game game;

  @override
  State<BroadcastButton> createState() => _BroadcastButtonState();
}

class _BroadcastButtonState extends State<BroadcastButton> {
  late final StreamProvider _provider;

  late bool _state;

  @override
  void initState() {
    super.initState();
    _state = false;
  }

  @override
  void didChangeDependencies() {
    _provider = StreamProvider.of(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (_state) {
      return FloatingActionButton(
        onPressed: _stopBroadcast,
        child: const Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.0,
          ),
        ),
      );
    }
    return FloatingActionButton(
      onPressed: _startBroadcast,
      child: const Icon(Icons.broadcast_on_home),
    );
  }

  void _startBroadcast() {
    _provider.startBroadcast(widget.game, _onBroadcastStop);
    setState(() => _state = true);
  }

  void _stopBroadcast() {
    _provider.stopBroadcast();
  }

  void _onBroadcastStop() {
    setState(() => _state = false);
  }
}
