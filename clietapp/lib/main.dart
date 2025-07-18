import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_config.dart';
// import 'services/production_deployment_manager.dart'; // Temporarily disabled
import 'services/production_ai_service.dart';
import 'services/production_voice_service.dart';
import 'services/production_calendar_service.dart';
import 'utils/google_calendar_service_stub.dart';
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

  print('🚀 Starting ${AppConfig.appName} v${AppConfig.version}...');
  print(
    '📱 Running in ${AppConfig.isProduction ? 'PRODUCTION' : 'DEVELOPMENT'} mode',
  );

  // Initialize Production Services using Deployment Manager
  // Temporarily disabled to prevent startup issues
  // if (AppConfig.isProduction) {
  //   final deploymentResult =
  //       await ProductionDeploymentManager.initializeProduction();
  //   if (deploymentResult.isSuccess) {
  //     print('✅ Production deployment completed successfully!');
  //   } else {
  //     print('❌ Production deployment failed: ${deploymentResult.message}');
  //   }
  // } else {
  //   await _initializeTestServices();
  // }

  // Use basic initialization for now
  await _initializeTestServices();

  // Initialize Google Calendar Service (existing)
  EnhancedGoogleCalendarService.initializeRoomCalendars();

  runApp(const ThemeModeProvider(child: NotionBookApp()));
}

Future<void> _initializeTestServices() async {
  print('🧪 Initializing Test Services...');

  try {
    // Initialize services in test mode
    await ProductionAIService.initialize();
    await ProductionVoiceService.initialize();
    await ProductionCalendarService.initialize();

    print('✅ Test services initialized successfully');
  } catch (e) {
    print('❌ Failed to initialize test services: $e');
  }
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
            // Use production or sample data based on configuration
            if (AppConfig.isProduction && AppConfig.isConfigured) {
              print('🔄 Using production data source');
              // Production data will be loaded from Firebase
            } else {
              print('🧪 Using sample data for testing');
              provider.forceSampleData();
            }
            return provider;
          },
          child: MaterialApp(
            title: AppConfig.appName,
            theme: notionTheme,
            debugShowCheckedModeBanner: !AppConfig.isProduction,
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
