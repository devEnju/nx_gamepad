import 'package:flutter/material.dart';

class ProblemLayout extends StatelessWidget {
  const ProblemLayout(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(text),
    );
  }
}
