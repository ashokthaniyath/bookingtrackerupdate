import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  final Widget child;
  const AuthGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Simplified auth gate - no authentication required
    // Just pass through to the child widget
    return child;
  }
}
