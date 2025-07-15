import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'services/enhanced_firebase_service.dart';
// import 'services/vertex_ai_service.dart';
// import 'services/google_auth_service.dart';

import 'utils/google_calendar_service.dart';
import 'screens/main_scaffold.dart';
import 'screens/auth_gate.dart';
import 'screens/sign_in_screen.dart';
import 'theme.dart';
import 'screens/room_status.dart';
import 'screens/booking_form.dart';
import 'screens/room_management_enhanced.dart';
import 'screens/guest_management_enhanced.dart';
import 'screens/payments_enhanced.dart';
import 'screens/analytics_enhanced.dart';
import 'screens/profile_page.dart';
import 'theme_mode_provider.dart';
import 'utils/theme_notifier.dart';
import 'providers/resort_data_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase and Firestore (temporarily disabled for debugging)
  /*
  try {
    await EnhancedFirebaseService.initialize();
    print('Enhanced Firebase Service initialized successfully');

    // Initialize sample data if needed
    await EnhancedFirebaseService.initializeSampleData();
  } catch (e) {
    print('Failed to initialize Enhanced Firebase Service: $e');
  }

  // Initialize Vertex AI Service
  try {
    await VertexAIService.initialize();
    print('Vertex AI Service initialized successfully');

    // Test the AI assistant to ensure it's working correctly
    await VertexAIService.testBookingAI();
  } catch (e) {
    print('Failed to initialize Vertex AI Service: $e');
  }
  */

  // Initialize Google Authentication Service
  /*
  try {
    await GoogleAuthService.initialize();
    print('Google Authentication initialized successfully');
  } catch (e) {
    print('Failed to initialize Google Authentication: $e');
  }
  */

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
        return ChangeNotifierProvider<ResortDataProvider>(
          create: (context) {
            final provider = ResortDataProvider();
            // Use sample data for development to avoid Firebase build issues
            provider.forceSampleData();
            return provider;
          },
          child: MaterialApp(
            title: 'NotionBook – Guest Booking Manager',
            theme: notionTheme,
            debugShowCheckedModeBanner: false,
            home: const AuthGate(child: MainScaffold()),
            routes: {
              // Authentication routes
              '/sign-in': (context) => const SignInScreen(),

              // Fix: Reconfigured routes - Core pages via bottom nav
              '/home': (context) => const MainScaffold(initialIndex: 0),
              '/calendar': (context) => const MainScaffold(initialIndex: 1),
              '/invoices': (context) => const MainScaffold(initialIndex: 2),
              '/booking': (context) => const MainScaffold(initialIndex: 3),

              // Secondary pages via drawer navigation
              '/rooms': (context) => const RoomManagementPage(),
              '/guests': (context) => const GuestManagementPage(),
              '/payment': (context) => const PaymentsPage(),
              '/analytics': (context) => const DashboardAnalyticsScreen(),
              '/profile': (context) => const ProfilePage(),

              // Legacy routes for compatibility
              '/dashboard': (context) => const MainScaffold(initialIndex: 0),
              '/sales': (context) => const PaymentsPage(),
              '/policy': (context) => const MainScaffold(initialIndex: 0),
              '/room_status': (context) => const RoomStatusScreen(),
              '/room-status': (context) => const RoomStatusScreen(),
              '/booking-form': (context) => const BookingFormPage(),
            },
          ),
        );
      },
    );
  }
}

// Removed the signOut function as FirebaseAuth is no longer used
