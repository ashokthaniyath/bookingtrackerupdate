import 'package:flutter/material.dart';
import '../config/environment.dart';
import '../utils/database_cleanup_service.dart';
import '../providers/resort_data_provider.dart';

class FrontendTestUtils {
  /// Test Supabase connection and configuration
  static Future<Map<String, dynamic>> testSupabaseConnection() async {
    try {
      final configStatus = EnvironmentConfig.getConfigStatus();

      if (!EnvironmentConfig.isSupabaseConfigured) {
        return {
          'success': false,
          'error':
              'Supabase not configured. Please check your environment setup.',
          'config': configStatus,
        };
      }

      // Test database connection by getting table counts
      final tableCounts = await DatabaseCleanupService.getTableCounts();

      return {
        'success': true,
        'message': 'Supabase connection successful!',
        'config': configStatus,
        'table_counts': tableCounts,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection failed: $e',
        'config': EnvironmentConfig.getConfigStatus(),
      };
    }
  }

  /// Test data provider functionality
  static Future<Map<String, dynamic>> testDataProvider() async {
    try {
      final provider = ResortDataProvider();
      await provider.loadData();

      return {
        'success': true,
        'data': {
          'bookings': provider.bookings.length,
          'rooms': provider.rooms.length,
          'guests': provider.guests.length,
          'payments': provider.payments.length,
        },
      };
    } catch (e) {
      return {'success': false, 'error': 'Data provider test failed: $e'};
    }
  }

  /// Show a test dialog with system status
  static void showSystemStatus(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔧 System Status'),
        content: FutureBuilder<Map<String, dynamic>>(
          future: testSupabaseConnection(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Testing connection...'),
                ],
              );
            }

            final result = snapshot.data ?? {};
            final isSuccess = result['success'] ?? false;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isSuccess ? Icons.check_circle : Icons.error,
                      color: isSuccess ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isSuccess ? 'Connected' : 'Connection Failed',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSuccess ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (result['table_counts'] != null) ...[
                  const Text('📊 Database Tables:'),
                  ...((result['table_counts'] as Map<String, int>).entries.map(
                    (entry) => Text('  ${entry.key}: ${entry.value} records'),
                  )),
                ],
                if (result['error'] != null) ...[
                  const Text('❌ Error:'),
                  Text(result['error'].toString()),
                ],
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Initialize sample data for testing
  static Future<void> initializeSampleData() async {
    try {
      final provider = ResortDataProvider();
      await provider.initializeSampleData();
    } catch (e) {
      debugPrint('Error initializing sample data: $e');
    }
  }
}
