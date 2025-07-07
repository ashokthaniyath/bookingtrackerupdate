import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  final Widget child;
  const AuthGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Always show the app, no sign in required
    return child;
  }
}
