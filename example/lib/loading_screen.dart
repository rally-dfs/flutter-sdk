import 'package:flutter/material.dart';

import 'components/custom_text.dart';

class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Use your desired background color
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 60),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HeadingText(text: 'Loading RLY Account'),
              SizedBox(height: 12),
              BodyText(text: 'This may take several seconds'),
              SizedBox(height: 24),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
