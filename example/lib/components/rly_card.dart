import 'package:flutter/material.dart';

class RlyCard extends StatelessWidget {
  final Widget child;
  final BoxDecoration? style;

  const RlyCard({super.key, required this.child, this.style});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: style?.copyWith(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey[600]!,
          width: 1,
        ),
      ),
      constraints: BoxConstraints(
        minWidth: MediaQuery.of(context).size.width * 0.9,
      ),
      child: child,
    );
  }
}
