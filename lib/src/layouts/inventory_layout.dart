import 'dart:io';

import 'package:flutter/material.dart' hide Action;

import '../utils/connection.dart';
import '../utils/protocol.dart';

import '../widgets/item_card.dart';

class InventoryLayout extends StatefulWidget {
  const InventoryLayout(
    this.socket,
    this.address,
    this.data, {
    super.key,
  });

  final RawDatagramSocket socket;
  final InternetAddress address;
  final List<int> data;

  @override
  State<InventoryLayout> createState() => _InventoryLayoutState();
}

class _InventoryLayoutState extends State<InventoryLayout> {
  int? _state;

  @override
  Widget build(BuildContext context) {
    const double scale = 7.0;
    final double pixel = scale / MediaQuery.of(context).devicePixelRatio;

    return Row(
      children: [
        Expanded(
          flex: 6,
          child: Container(),
        ),
        Expanded(
          flex: 9,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  for (int i = 9; i < 18; i++)
                    _buildItemCard(i, pixel, widget.data),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  for (int i = 18; i < 27; i++)
                    _buildItemCard(i, pixel, widget.data),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  for (int i = 27; i < 36; i++)
                    _buildItemCard(i, pixel, widget.data),
                ],
              ),
              SizedBox(height: pixel * 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  for (int i = 36; i < 45; i++)
                    _buildItemCard(i, pixel, widget.data),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(int index, double pixel, List<int> data) {
    final int byte1 = data[(index - 9) * 2];
    final int byte2 = data[(index - 9) * 2 + 1];

    final int id = byte1 + ((byte2 & 0xc0) << 2);
    final int amount = (byte2 & 0x3f) + 1;

    if (_state == index && id == 0) {
      _state = null;
    }

    return ItemCard(
      id,
      amount,
      pixel,
      color: _state != index
          ? const Color.fromARGB(255, 139, 139, 139)
          : const Color.fromARGB(255, 197, 197, 197),
      onTap: () => _tileSelection(index, id),
    );
  }

  void _tileSelection(int index, int id) {
    if (_state == index) {
      setState(() {
        _state = null;
      });
    } else if (_state != null) {
      widget.socket.send(
        [Client.action.value, GameAction.swapItem.index, _state!, index],
        widget.address,
        Connection.port,
      );
      setState(() {
        _state = null;
      });
    } else if (id != 0) {
      setState(() {
        _state = index;
      });
    }
  }
}
