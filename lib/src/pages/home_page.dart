import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../layouts/connection_layout.dart';

import '../pages/game_page.dart';

import '../utils/connection.dart';
import '../utils/protocol.dart';

class HomePage extends StatefulWidget {
  const HomePage(this.socket, {super.key});

  final RawDatagramSocket socket;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Set<InternetAddress> _addresses = {};

  late Stream<Datagram?> _stream;

  InternetAddress? _connection;
  StreamController<Uint8List>? _controller;

  @override
  void initState() {
    super.initState();

    _stream = widget.socket.map<Datagram?>((event) {
      if (event == RawSocketEvent.read) {
        final datagram = widget.socket.receive();

        if (datagram != null && datagram.data.length > 1) {
          final message = datagram.data[0];

          if (message < 4) {
            return datagram;
          }
          if (_connection == datagram.address) {
            if (_controller == null) {
              if (message == Server.state.value) {
                _setupPlatform(() => _openGamePage(datagram));
              }
            } else if (message == Server.update.value) {
              // to register independent streams for frequent updates of single widgets
            } else {
              _controller!.add(datagram.data);
            }
          }
        }
      }
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('nx Gamepad'),
        centerTitle: true,
      ),
      body: StreamBuilder<Datagram?>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final datagram = snapshot.data!;

            final message = datagram.data[0];
            final address = datagram.address;

            if (message == Server.info.value) {
              _addresses.add(address);
            } else if (message == Server.quit.value) {
              if (_connection == address) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (timeStamp) => Navigator.of(context).pop(),
                );
              }
              _addresses.remove(address);
            }
          }

          return ConnectionLayout(
            _addresses,
            _selectConnection,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _broadcastGamepad(),
        child: const Icon(Icons.broadcast_on_home),
      ),
    );
  }

  void _broadcastGamepad() {
    widget.socket.broadcastEnabled = true;
    widget.socket.send(
      <int>[Client.broadcast.value, 255, 255, 255, 255],
      InternetAddress('255.255.255.255'),
      Connection.port,
    );
    widget.socket.broadcastEnabled = false;
  }

  void _selectConnection(InternetAddress address) {
    _connection = address;

    widget.socket.send(
      <int>[Client.state.value, GameState.menu.index],
      address,
      Connection.port,
    );
  }

  Future<void> _setupPlatform(void Function() onSuccess) async {
    final value = await Connection.methodChannel.invokeMethod<bool>(
      'setAddress',
      <String, String>{
        'address': _connection!.address,
        'port': '${Connection.port}',
      },
    );

    if (value != null) {
      onSuccess();
    }
  }

  void _openGamePage(Datagram datagram) {
    _controller = StreamController<Uint8List>();

    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GamePage(
            widget.socket,
            _connection!,
            datagram.data,
            _controller!,
            _closeGamePage,
          ),
        ),
      ),
    );
  }

  void _closeGamePage() {
    Connection.methodChannel.invokeMethod<bool>('resetAddress');
    _controller = null;
    _connection = null;
    _broadcastGamepad();
  }
}
