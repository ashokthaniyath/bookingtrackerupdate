import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/resort_data_provider.dart';
import 'utils/theme_notifier.dart';
import 'screens/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sample data directly without Firebase
  final resortProvider = ResortDataProvider();
  await resortProvider.forceSampleData();

  runApp(BookingTrackerApp(resortProvider: resortProvider));
}

class BookingTrackerApp extends StatelessWidget {
  final ResortDataProvider resortProvider;

  const BookingTrackerApp({super.key, required this.resortProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ResortDataProvider>.value(value: resortProvider),
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, child) {
          return MaterialApp(
            title: 'Booking Tracker',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              primarySwatch: Colors.blue,
              brightness: Brightness.dark,
            ),
            themeMode: themeNotifier.themeMode,
            home: const MainScaffold(),
          );
        },
      ),
    );
  }
}
