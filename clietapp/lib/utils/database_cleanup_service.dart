import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseCleanupService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Delete all data from all tables (keeps table structure)
  static Future<void> deleteAllData() async {
    try {
      print('Starting database cleanup...');

      // Delete in order to avoid foreign key constraints
      await _client.from('calendar_notifications').delete().neq('id', '');
      print('✅ Deleted all calendar notifications');

      await _client.from('unavailable_hours').delete().neq('id', '');
      print('✅ Deleted all unavailable hours');

      await _client.from('room_calendars').delete().neq('id', '');
      print('✅ Deleted all room calendars');

      await _client.from('payments').delete().neq('id', '');
      print('✅ Deleted all payments');

      await _client.from('bookings').delete().neq('id', '');
      print('✅ Deleted all bookings');

      await _client.from('guests').delete().neq('id', '');
      print('✅ Deleted all guests');

      await _client.from('rooms').delete().neq('id', '');
      print('✅ Deleted all rooms');

      print('🎉 Database cleanup completed successfully!');
    } catch (e) {
      print('❌ Error during database cleanup: $e');
      rethrow;
    }
  }

  /// Delete specific table data
  static Future<void> deleteTableData(String tableName) async {
    try {
      await _client.from(tableName).delete().neq('id', '');
      print('✅ Deleted all data from $tableName');
    } catch (e) {
      print('❌ Error deleting data from $tableName: $e');
      rethrow;
    }
  }

  /// Delete data older than specified days
  static Future<void> deleteOldData(int daysOld) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      final cutoffString = cutoffDate.toIso8601String();

      // Delete old bookings
      await _client.from('bookings').delete().lt('created_at', cutoffString);

      // Delete old payments
      await _client.from('payments').delete().lt('created_at', cutoffString);

      print('✅ Deleted data older than $daysOld days');
    } catch (e) {
      print('❌ Error deleting old data: $e');
      rethrow;
    }
  }

  /// Count records in all tables
  static Future<Map<String, int>> getTableCounts() async {
    final Map<String, int> counts = {};
    final tables = [
      'bookings',
      'guests',
      'rooms',
      'payments',
      'room_calendars',
      'unavailable_hours',
      'calendar_notifications',
    ];

    for (String table in tables) {
      try {
        final response = await _client.from(table).select('*');
        counts[table] = response.length;
      } catch (e) {
        print('Error counting $table: $e');
        counts[table] = 0;
      }
    }

    return counts;
  }

  /// Print database statistics
  static Future<void> printDatabaseStats() async {
    print('\n📊 DATABASE STATISTICS:');
    print('━' * 40);

    final counts = await getTableCounts();
    counts.forEach((table, count) {
      print('$table: $count records');
    });

    final total = counts.values.fold(0, (sum, count) => sum + count);
    print('━' * 40);
    print('TOTAL RECORDS: $total');
    print('');
  }
}
