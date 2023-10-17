import 'package:flutter/material.dart';

class BodyText extends StatelessWidget {
  final String text;

  BodyText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white,
      ),
    );
  }
}

class HeadingText extends StatelessWidget {
  final String text;

  HeadingText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
    );
  }
}
