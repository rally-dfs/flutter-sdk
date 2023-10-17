import 'package:flutter/material.dart';

import 'custom_text.dart';

class LoadingModal extends StatelessWidget {
  final bool show;
  final String title;

  const LoadingModal({super.key, required this.show, required this.title});

  @override
  Widget build(BuildContext context) {
    return StandardModal(
      show: show,
      children: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          HeadingText(text: title),
          const SizedBox(height: 12),
          const CircularProgressIndicator(),
        ],
      ),
    );
  }
}

class StandardModal extends StatelessWidget {
  final bool show;
  final Widget children;

  const StandardModal({super.key, required this.show, required this.children});

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: show,
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          padding: const EdgeInsets.all(35),
          child: children,
        ),
      ),
    );
  }
}
