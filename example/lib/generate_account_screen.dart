import 'package:flutter/material.dart';

import 'components/app_container.dart';
import 'components/custom_text.dart';
import 'components/rly_card.dart';

class GenerateAccountScreen extends StatelessWidget {
  final VoidCallback generateAccount;

  const GenerateAccountScreen({super.key, required this.generateAccount});

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const HeadingText(text: 'Welcome To Rally Protocol Demo App'),
          RlyCard(
            child: Column(
              children: [
                const SizedBox(height: 12),
                const BodyText(
                    text: "Looks like you don't yet have an account"),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: generateAccount,
                  child: const Text('Create EOA Account'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
