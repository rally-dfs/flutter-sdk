import 'package:flutter/material.dart';

import 'components/AppContainer.dart';
import 'components/CustomText.dart';
import 'components/RlyCard.dart';

class GenerateAccountScreen extends StatelessWidget {
  final VoidCallback generateAccount;

  GenerateAccountScreen({required this.generateAccount});

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          HeadingText(text: 'Welcome To Rally Protocol Demo App'),
          RlyCard(
            child: Column(
              children: [
                SizedBox(height: 12),
                BodyText(text: "Looks like you don't yet have an account"),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: generateAccount,
                  child: Text('Create EOA Account'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
