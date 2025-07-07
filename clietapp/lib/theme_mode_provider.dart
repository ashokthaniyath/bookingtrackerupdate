import 'package:flutter/material.dart';
import 'utils/theme_notifier.dart';
import 'package:provider/provider.dart';

class ThemeModeProvider extends StatelessWidget {
  final Widget child;
  const ThemeModeProvider({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(create: (_) => ThemeNotifier(), child: child);
  }
}
