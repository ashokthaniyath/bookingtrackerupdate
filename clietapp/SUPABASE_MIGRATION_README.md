# Supabase Migration Guide

This guide outlines the complete migration from Hive (local storage) and Firebase to Supabase for the Booking Tracker application.

## Migration Summary

### What was changed:

1. **Removed Dependencies:**

   - `hive: ^2.2.3`
   - `hive_flutter: ^1.1.0`
   - `hive_generator: ^2.0.1`
   - `build_runner: ^2.1.0`

2. **Updated Models:**

   - Removed Hive annotations and HiveObject inheritance
   - Added Supabase serialization methods
   - Added ID fields for database records

3. **Created New Services:**

   - `SupabaseService`: Complete CRUD operations for all entities
   - Updated `ResortDataProvider`: Uses Supabase instead of Hive

4. **Updated Authentication:**
   - Replaced Firebase auth with Supabase auth
   - Added proper authentication flow (optional)

## Setup Instructions

### 1. Supabase Project Setup

1. Create a new project at [supabase.com](https://supabase.com)
2. Copy your project URL and anon key
3. Execute the SQL schema in `supabase_migration.sql` in your Supabase SQL editor

### 2. Environment Configuration

Set your Supabase key as an environment variable:

**Development:**

```bash
# Run with environment variable
flutter run --dart-define=SUPABASE_KEY=your_actual_supabase_anon_key_here
```

**Production:**

- Set `SUPABASE_KEY` in your deployment environment
- Update `supabaseUrl` in `main.dart` if needed

### 3. Database Schema

The following tables are created:

- `guests`: Store guest information
- `rooms`: Store room details and status
- `bookings`: Store booking information
- `payments`: Store payment records

### 4. Real-time Features

The app now supports real-time updates through Supabase's real-time subscriptions:

- Changes to any table are automatically reflected in the UI
- Multiple users can see updates instantly

## Key Features

### Authentication (Optional)

- Email/password authentication through Supabase
- Can be easily enabled by modifying `AuthGate`
- Currently set to allow access without authentication

### CRUD Operations

All CRUD operations are handled through `SupabaseService`:

- `getBookings()`, `addBooking()`, `updateBooking()`, `deleteBooking()`
- `getRooms()`, `addRoom()`, `updateRoom()`, `deleteRoom()`
- `getGuests()`, `addGuest()`, `updateGuest()`, `deleteGuest()`
- `getPayments()`, `addPayment()`, `updatePayment()`, `deletePayment()`

### Real-time Updates

- `bookingsStream`, `roomsStream`, `guestsStream`, `paymentsStream`
- Automatic UI updates when data changes

## Running the Application

1. Install dependencies:

```bash
flutter pub get
```

2. Run the application:

```bash
flutter run --dart-define=SUPABASE_KEY=your_supabase_anon_key
```

## Migration Benefits

1. **Cloud Storage**: Data is now stored in the cloud instead of locally
2. **Real-time Sync**: Multiple devices can stay in sync
3. **Scalability**: Supabase can handle much larger datasets
4. **Backup**: Automatic cloud backup of all data
5. **Authentication**: Built-in user management system
6. **APIs**: RESTful APIs for external integrations

## Row Level Security (RLS)

The database schema includes basic RLS policies that allow all operations. For production use, you should:

1. Enable proper authentication
2. Create restrictive RLS policies
3. Limit access based on user roles

Example of restrictive policy:

```sql
CREATE POLICY "Users can only see their own bookings" ON bookings
    FOR ALL USING (auth.uid() = user_id);
```

## Notes

- The migration maintains backward compatibility with existing serialization methods
- Legacy `toMap()` and `fromMap()` methods are preserved for compatibility
- Real-time features can be disabled if not needed
- The app will work offline with cached data (Supabase handles this automatically)

## Troubleshooting

1. **Authentication Issues**: Ensure SUPABASE_KEY is set correctly
2. **Database Errors**: Check that the SQL schema was executed properly
3. **Network Issues**: Supabase requires internet connection for initial load
4. **RLS Errors**: Check that policies allow the operations you're attempting

## Next Steps

1. Set up proper authentication if needed
2. Configure Row Level Security policies
3. Add data validation rules
4. Set up backup procedures
5. Monitor usage in Supabase dashboard
