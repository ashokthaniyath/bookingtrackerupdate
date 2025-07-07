import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/room.dart';
import '../models/booking.dart';
import '../widgets/custom_bottom_navigation_bar.dart';

class RoomStatusScreen extends StatelessWidget {
  const RoomStatusScreen({super.key});

  void _onTabSelected(int index, BuildContext context) {
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/dashboard',
        (route) => false,
      );
    } else if (index == 1) {
      Navigator.pushNamedAndRemoveUntil(context, '/calendar', (route) => false);
    } else if (index == 2) {
      Navigator.pushNamedAndRemoveUntil(context, '/profile', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomBox = Hive.isBoxOpen('rooms') ? Hive.box<Room>('rooms') : null;
    final bookingBox = Hive.isBoxOpen('bookings')
        ? Hive.box<Booking>('bookings')
        : null;
    if (roomBox == null || bookingBox == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return ValueListenableBuilder(
      valueListenable: roomBox.listenable(),
      builder: (context, Box<Room> roomBox, _) {
        final rooms = roomBox.values.toList();
        return ValueListenableBuilder(
          valueListenable: bookingBox.listenable(),
          builder: (context, Box<Booking> bookingBox, _) {
            final bookings = bookingBox.values.toList();
            Map<String, List<Booking>> roomBookings = {};
            for (final room in rooms) {
              roomBookings[room.number] = bookings
                  .where((b) => b.room.number == room.number)
                  .toList();
            }
            return Scaffold(
              appBar: AppBar(title: const Text('Room Status')),
              body: rooms.isEmpty
                  ? const Center(child: Text('No rooms found.'))
                  : ListView.builder(
                      itemCount: rooms.length,
                      itemBuilder: (context, i) {
                        final room = rooms[i];
                        final bookingsForRoom = roomBookings[room.number] ?? [];
                        final isBooked = bookingsForRoom.isNotEmpty;
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading: Icon(
                              isBooked
                                  ? Icons.meeting_room
                                  : Icons.meeting_room_outlined,
                              color: isBooked ? Colors.red : Colors.green,
                            ),
                            title: Text('Room ${room.number} (${room.type})'),
                            subtitle: isBooked
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: bookingsForRoom
                                        .map(
                                          (b) => Text(
                                            'Booked: ${b.checkIn.day}/${b.checkIn.month} - ${b.checkOut.day}/${b.checkOut.month}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  )
                                : const Text('Available'),
                          ),
                        );
                      },
                    ),
              bottomNavigationBar: CustomBottomNavigation(
                selectedIndex: 0, // or 1/2 depending on context
                onItemTapped: (index) => _onTabSelected(index, context),
              ),
            );
          },
        );
      },
    );
  }
}
