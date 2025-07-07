import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'utils/hive_init.dart';
import 'utils/google_calendar_service.dart';
import 'screens/main_scaffold.dart';
import 'screens/auth_gate.dart';
import 'theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/room_status.dart';
import 'screens/booking_form.dart';
import 'theme_mode_provider.dart';
import 'utils/theme_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await initializeHiveBoxes();

  // New Feature: Initialize Enhanced Google Calendar Service
  final calendarService = EnhancedGoogleCalendarService();
  calendarService.initializeRoomCalendars();

  runApp(const ThemeModeProvider(child: NotionBookApp()));
}

class NotionBookApp extends StatelessWidget {
  const NotionBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, _) {
        return MaterialApp(
          title: 'NotionBook – Guest Booking Manager',
          theme: notionTheme,
          debugShowCheckedModeBanner: false,
          home: const AuthGate(child: MainScaffold()),
          routes: {
            '/dashboard': (context) => const MainScaffold(initialIndex: 0),
            '/rooms': (context) => const MainScaffold(initialIndex: 1),
            '/guests': (context) => const MainScaffold(initialIndex: 2),
            '/sales': (context) => const MainScaffold(initialIndex: 3),
            '/analytics': (context) => const MainScaffold(initialIndex: 4),
            '/calendar': (context) => const MainScaffold(initialIndex: 1),
            '/profile': (context) => const MainScaffold(initialIndex: 2),
            '/policy': (context) => const DashboardScreen(),
            '/room_status': (context) => const RoomStatusScreen(),
            '/room-status': (context) => const RoomStatusScreen(),
            '/booking-form': (context) => const BookingFormPage(),
          },
        );
      },
    );
  }
}

// Removed the signOut function as FirebaseAuth is no longer used
