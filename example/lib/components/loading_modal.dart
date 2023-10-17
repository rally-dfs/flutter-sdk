import 'package:flutter/material.dart';

import 'custom_text.dart';

class LoadingModal extends StatelessWidget {
  final bool show;
  final String title;

  LoadingModal({required this.show, required this.title});

  @override
  Widget build(BuildContext context) {
    return StandardModal(
      show: show,
      children: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          HeadingText(text: title),
          SizedBox(height: 12),
          CircularProgressIndicator(),
        ],
      ),
    );
  }
}

class StandardModal extends StatelessWidget {
  final bool show;
  final Widget children;

  StandardModal({required this.show, required this.children});

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: show,
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black,
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          padding: EdgeInsets.all(35),
          child: children,
        ),
      ),
    );
  }
}
