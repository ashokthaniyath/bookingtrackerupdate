# Database Deletion Guide - Supabase

## 🗑️ How to Delete Your Database Data

### **Method 1: Using Supabase Dashboard (Recommended)**

1. **Go to your Supabase project**:

   - Visit [https://supabase.com/dashboard](https://supabase.com/dashboard)
   - Select your project

2. **Navigate to SQL Editor**:

   - Click on "SQL Editor" in the left sidebar
   - Click "New query"

3. **Delete all data (keep tables)**:

   ```sql
   -- Delete all data from all tables
   DELETE FROM calendar_notifications;
   DELETE FROM unavailable_hours;
   DELETE FROM room_calendars;
   DELETE FROM payments;
   DELETE FROM bookings;
   DELETE FROM guests;
   DELETE FROM rooms;
   ```

4. **Or drop all tables completely**:
   ```sql
   -- WARNING: This deletes everything including table structure
   DROP TABLE IF EXISTS calendar_notifications CASCADE;
   DROP TABLE IF EXISTS unavailable_hours CASCADE;
   DROP TABLE IF EXISTS room_calendars CASCADE;
   DROP TABLE IF EXISTS payments CASCADE;
   DROP TABLE IF EXISTS bookings CASCADE;
   DROP TABLE IF EXISTS guests CASCADE;
   DROP TABLE IF EXISTS rooms CASCADE;
   ```

### **Method 2: Using Your Flutter App**

I've created a `DatabaseCleanupService` for you. Here's how to use it:

1. **Add this to your app** (already created at `lib/utils/database_cleanup_service.dart`)

2. **Use in your Flutter code**:

   ```dart
   import 'package:your_app/utils/database_cleanup_service.dart';

   // Delete all data
   await DatabaseCleanupService.deleteAllData();

   // Check what's in your database first
   await DatabaseCleanupService.printDatabaseStats();

   // Delete specific table
   await DatabaseCleanupService.deleteTableData('bookings');

   // Delete old data (older than 30 days)
   await DatabaseCleanupService.deleteOldData(30);
   ```

### **Method 3: Complete Database Reset**

If you want to start completely fresh:

1. **In Supabase SQL Editor**, run:

   ```sql
   -- Nuclear option: Delete everything and start fresh
   DROP SCHEMA public CASCADE;
   CREATE SCHEMA public;
   GRANT ALL ON SCHEMA public TO postgres;
   GRANT ALL ON SCHEMA public TO public;
   ```

2. **Then re-run your schema**:
   - Copy your `comprehensive_database_schema.sql`
   - Paste it in SQL Editor and run it

### **⚠️ Important Warnings**

- **BACKUP FIRST**: Always export your data before deleting
- **No Undo**: Database deletions are permanent
- **Test Environment**: Try deletions on a test project first
- **Foreign Keys**: Some deletions might fail due to relationships

### **🔧 Quick Actions**

**To delete everything and start fresh:**

1. Go to Supabase Dashboard → SQL Editor
2. Run: `DELETE FROM calendar_notifications; DELETE FROM unavailable_hours; DELETE FROM room_calendars; DELETE FROM payments; DELETE FROM bookings; DELETE FROM guests; DELETE FROM rooms;`
3. Verify with: `SELECT COUNT(*) FROM bookings;` (should return 0)

**To check what's in your database:**

1. Use your Flutter app and call: `DatabaseCleanupService.printDatabaseStats()`
2. Or in Supabase: `SELECT COUNT(*) FROM bookings;` for each table

Your database will be clean and ready for fresh data! 🎉
