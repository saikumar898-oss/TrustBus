import 'package:flutter/material.dart';

class Responsive extends StatelessWidget {
  final Widget child;
  const Responsive({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).size.width > 800) {
      return Center(
        child: SizedBox(width: 450, child: child),
      );
    }
    return child;
  }
}
