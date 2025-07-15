import 'package:flutter/material.dart';
import '../providers/resort_data_provider.dart';
import '../services/firestore_service.dart';

class FrontendTestUtils {
  /// Test Firestore connection and configuration
  static Future<Map<String, dynamic>> testFirestoreConnection() async {
    try {
      if (!FirestoreService.isInitialized) {
        return {
          'success': false,
          'error':
              'Firestore not initialized. Please check your Firebase setup.',
        };
      }

      // Test database connection by getting collection counts
      final collectionCounts = await FirestoreService.getCollectionCounts();

      return {
        'success': true,
        'message': 'Firestore connection successful!',
        'collection_counts': collectionCounts,
        'collections': {
          'bookings': FirestoreService.BOOKINGS_COLLECTION,
          'guests': FirestoreService.GUESTS_COLLECTION,
          'rooms': FirestoreService.ROOMS_COLLECTION,
          'payments': FirestoreService.PAYMENTS_COLLECTION,
          'users': FirestoreService.USERS_COLLECTION,
          'analytics': FirestoreService.ANALYTICS_COLLECTION,
        },
      };
    } catch (e) {
      return {'success': false, 'error': 'Firestore connection failed: $e'};
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
          future: testFirestoreConnection(),
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
                if (result['collection_counts'] != null) ...[
                  const Text('📊 Firestore Collections:'),
                  ...((result['collection_counts'] as Map<String, int>).entries
                      .map(
                        (entry) =>
                            Text('  ${entry.key}: ${entry.value} records'),
                      )),
                  const SizedBox(height: 8),
                  const Text('📝 Collection IDs:'),
                  if (result['collections'] != null)
                    ...((result['collections'] as Map<String, String>).entries
                        .map(
                          (entry) => Text('  ${entry.key}: "${entry.value}"'),
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
      await provider.loadData();

      // Add sample data to Firestore if collections are empty
      final counts = await FirestoreService.getCollectionCounts();
      if (counts[FirestoreService.BOOKINGS_COLLECTION] == 0) {
        // Add sample analytics event
        await FirestoreService.recordAnalytics('app_initialized', {
          'timestamp': DateTime.now().toIso8601String(),
          'userId': 'demo_user',
          'action': 'sample_data_initialization',
        });
        debugPrint('Sample analytics data added to Firestore');
      }
    } catch (e) {
      debugPrint('Error initializing sample data: $e');
    }
  }

  /// Test Firestore operations with sample data
  static Future<Map<String, dynamic>> testFirestoreOperations() async {
    try {
      if (!FirestoreService.isInitialized) {
        return {'success': false, 'error': 'Firestore not initialized'};
      }

      // Test analytics recording
      await FirestoreService.recordAnalytics('test_event', {
        'userId': 'test_user',
        'action': 'firestore_test',
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Get collection counts
      final counts = await FirestoreService.getCollectionCounts();

      return {
        'success': true,
        'message': 'Firestore operations test completed',
        'operations_tested': [
          'Analytics recording',
          'Collection count retrieval',
        ],
        'collection_counts': counts,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Firestore operations test failed: $e',
      };
    }
  }

  /// Create a Firestore test button widget
  static Widget buildFirestoreTestButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => showSystemStatus(context),
      icon: const Icon(Icons.cloud),
      label: const Text('Test Firestore'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
    );
  }
}
