import 'package:flutter/material.dart';

import '../providers/stream_provider.dart';

class BroadcastButton extends StatefulWidget {
  const BroadcastButton({super.key});

  @override
  State<BroadcastButton> createState() => _BroadcastButtonState();
}

class _BroadcastButtonState extends State<BroadcastButton> {
  late final StreamProvider _provider;

  @override
  void didChangeDependencies() {
    _provider = StreamProvider.of(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      initialData: false,
      stream: _provider.broadcast,
      builder: (context, snapshot) {
        if (snapshot.data!) {
          return FloatingActionButton(
            onPressed: () => _provider.stopBroadcast(),
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
          onPressed: () => _provider.startBroadcast(<int>[255, 255, 255]),
          child: const Icon(Icons.broadcast_on_home),
        );
      },
    );
  }
}
