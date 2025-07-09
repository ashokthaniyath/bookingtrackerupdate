import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/room.dart';
import '../models/booking.dart';
import 'package:google_fonts/google_fonts.dart';

class RoomManagementPage extends StatefulWidget {
  const RoomManagementPage({super.key});

  @override
  State<RoomManagementPage> createState() => _RoomManagementPageState();
}

class _RoomManagementPageState extends State<RoomManagementPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // UI Enhancement: Initialize Fade Animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showRoomDialog({Room? room}) {
    final numberController = TextEditingController(text: room?.number ?? '');
    final typeController = TextEditingController(text: room?.type ?? '');
    String status = room?.status ?? 'Available';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          room == null ? 'Add Room' : 'Edit Room',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: numberController,
              decoration: const InputDecoration(labelText: 'Room Number'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: typeController,
              decoration: const InputDecoration(labelText: 'Room Type'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: status,
              items: const [
                DropdownMenuItem(value: 'Available', child: Text('Available')),
                DropdownMenuItem(value: 'Occupied', child: Text('Occupied')),
                DropdownMenuItem(value: 'Cleaning', child: Text('Cleaning')),
                DropdownMenuItem(
                  value: 'Maintenance',
                  child: Text('Maintenance'),
                ),
              ],
              onChanged: (v) => status = v ?? 'Available',
              decoration: const InputDecoration(labelText: 'Status'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () async {
              final box = Hive.box<Room>('rooms');
              if (room == null) {
                await box.add(
                  Room(
                    number: numberController.text,
                    type: typeController.text,
                    status: status,
                  ),
                );
              } else {
                room.number = numberController.text;
                room.type = typeController.text;
                room.status = status;
                await room.save();
              }
              Navigator.pop(context);
              setState(() {});
            },
            child: Text(
              room == null ? 'Add' : 'Update',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteRoom(Room room) async {
    await room.delete();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final roomBox = Hive.box<Room>('rooms');
    final bookingBox = Hive.box<Booking>('bookings');
    final rooms = roomBox.values.toList();
    Room? selectedRoom = rooms.isNotEmpty ? rooms.first : null;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFb2e0ff), Color(0xFFeaf6ff), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Room Management',
            style: GoogleFonts.poppins(
              color: Colors.blue.shade900,
              fontWeight: FontWeight.bold,
              fontSize: 26,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.link, color: Colors.blueAccent),
              tooltip: 'Copy Public Calendar Link',
              onPressed: () {
                if (selectedRoom != null) {
                  final url = selectedRoom != null
                      ? 'https://resort-booking.com/public/${selectedRoom!.number.replaceAll(' ', '_').toLowerCase()}'
                      : '';
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Public link: $url')));
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.email_outlined, color: Colors.teal),
              tooltip: 'Send Reminder Email',
              onPressed: () {
                // Use url_launcher for email intent
                // (You must add url_launcher to pubspec.yaml)
              },
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: Colors.blueAccent),
                child: const Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildDrawerItem(
                context,
                Icons.attach_money_rounded,
                'Sales / Payment',
                '/sales',
              ),
              _buildDrawerItem(context, Icons.bed_rounded, 'Rooms', '/rooms'),
              _buildDrawerItem(
                context,
                Icons.people_alt_rounded,
                'Guest List',
                '/guests',
              ),
              _buildDrawerItem(
                context,
                Icons.analytics_outlined,
                'Analytics',
                '/analytics',
              ),
              _buildDrawerItem(
                context,
                Icons.add_box_rounded,
                'Booking',
                '/booking-form',
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room selector
                if (rooms.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFeaf6ff), Color(0xFFb2e0ff)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueGrey.withOpacity(0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.meeting_room,
                          color: Colors.blueAccent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButton<Room>(
                            value: selectedRoom,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down),
                            style: GoogleFonts.poppins(
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            underline: Container(),
                            borderRadius: BorderRadius.circular(16),
                            items: rooms
                                .map(
                                  (room) => DropdownMenuItem(
                                    value: room,
                                    child: Text('Room ${room.number}'),
                                  ),
                                )
                                .toList(),
                            onChanged: (room) {
                              setState(() {
                                selectedRoom = room;
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_box_rounded,
                            color: Colors.redAccent,
                          ),
                          tooltip: 'Add Unavailable Hours',
                          onPressed: () async {
                            // Show dialog to add unavailable hours (recurring)
                          },
                        ),
                      ],
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rooms',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => _showRoomDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: roomBox.listenable(),
                    builder: (context, Box<Room> roomBox, _) {
                      final rooms = roomBox.values.toList();
                      return ValueListenableBuilder(
                        valueListenable: bookingBox.listenable(),
                        builder: (context, Box<Booking> bookingBox, _) {
                          final bookings = bookingBox.values.toList();
                          return ListView.separated(
                            itemCount: rooms.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final room = rooms[i];
                              final roomBookings = bookings
                                  .where((b) => b.room.number == room.number)
                                  .toList();
                              // Determine color based on status only
                              final isAvailable = room.status == 'Available';
                              final roomColor = isAvailable
                                  ? Colors.green
                                  : Colors.red;
                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                color: Colors.white,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: roomColor.withOpacity(
                                      0.15,
                                    ),
                                    child: Icon(
                                      Icons.meeting_room_outlined,
                                      color: roomColor,
                                    ),
                                  ),
                                  title: Text(
                                    'Room ${room.number}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${room.type} • ${room.status}',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (roomBookings.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            '${roomBookings.length} booking(s)',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          color: Color(0xFF007AFF),
                                        ),
                                        onPressed: () =>
                                            _showRoomDialog(room: room),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Color(0xFFF43F5E),
                                        ),
                                        onPressed: () => _deleteRoom(room),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    String route,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: () {
        Navigator.pop(context);
        if (ModalRoute.of(context)?.settings.name != route) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }
}
