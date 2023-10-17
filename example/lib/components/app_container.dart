import 'package:flutter/material.dart';

class AppContainer extends StatelessWidget {
  final Widget child;

  AppContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Use your desired background color
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 60),
        child: Center(
          child: child,
        ),
      ),
    );
  }
}
