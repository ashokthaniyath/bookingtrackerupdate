import 'package:flutter/material.dart';
import '../models/room.dart';
import '../models/booking.dart';
import '../services/firestore_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

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
        backgroundColor: Colors.white,
        title: Text(
          room == null ? 'Add Room' : 'Edit Room',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E3A8A),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // UI Enhancement: Modern Text Fields
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFF8FAFC),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: numberController,
                style: GoogleFonts.poppins(),
                decoration: InputDecoration(
                  labelText: 'Room Number',
                  labelStyle: GoogleFonts.poppins(
                    color: const Color(0xFF64748B),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFF8FAFC),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: typeController,
                style: GoogleFonts.poppins(),
                decoration: InputDecoration(
                  labelText: 'Room Type',
                  labelStyle: GoogleFonts.poppins(
                    color: const Color(0xFF64748B),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFF8FAFC),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonFormField<String>(
                value: status,
                style: GoogleFonts.poppins(color: const Color(0xFF1E293B)),
                decoration: InputDecoration(
                  labelText: 'Status',
                  labelStyle: GoogleFonts.poppins(
                    color: const Color(0xFF64748B),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'Available',
                    child: Text('Available', style: GoogleFonts.poppins()),
                  ),
                  DropdownMenuItem(
                    value: 'Occupied',
                    child: Text('Occupied', style: GoogleFonts.poppins()),
                  ),
                  DropdownMenuItem(
                    value: 'Cleaning',
                    child: Text('Cleaning', style: GoogleFonts.poppins()),
                  ),
                  DropdownMenuItem(
                    value: 'Maintenance',
                    child: Text('Maintenance', style: GoogleFonts.poppins()),
                  ),
                ],
                onChanged: (v) => status = v ?? 'Available',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
            ),
          ),
          // UI Enhancement: Premium Button Style
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () async {
                try {
                  final newRoom = Room(
                    id: room?.id,
                    number: numberController.text,
                    type: typeController.text,
                    status: status,
                  );

                  if (room == null) {
                    await FirestoreService.addRoom(newRoom);
                  } else {
                    await FirestoreService.updateRoom(room.id!, {
                      'number': newRoom.number,
                      'type': newRoom.type,
                      'status': newRoom.status,
                    });
                  }

                  if (context.mounted) {
                    if (mounted) Navigator.pop(context);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: Text(
                room == null ? 'Add Room' : 'Update Room',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteRoom(Room room) async {
    try {
      await FirestoreService.deleteRoom(room.id!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting room: $e')));
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return const Color(0xFF14B8A6);
      case 'occupied':
        return const Color(0xFFF43F5E);
      case 'cleaning':
        return const Color(0xFFEAB308);
      case 'maintenance':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Icons.check_circle;
      case 'occupied':
        return Icons.person;
      case 'cleaning':
        return Icons.cleaning_services;
      case 'maintenance':
        return Icons.build;
      default:
        return Icons.help;
    }
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    String route,
  ) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF007AFF)),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // UI Enhancement: Luxury Gradient Background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF87CEEB), // Sky blue
              Color(0xFFFFFFFF), // White
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: StreamBuilder<List<Room>>(
              stream: FirestoreService.getRoomsStream(),
              builder: (context, roomSnapshot) {
                return StreamBuilder<List<Booking>>(
                  stream: FirestoreService.getBookingsStream(),
                  builder: (context, bookingSnapshot) {
                    if (roomSnapshot.connectionState ==
                            ConnectionState.waiting ||
                        bookingSnapshot.connectionState ==
                            ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (roomSnapshot.hasError || bookingSnapshot.hasError) {
                      return Center(child: Text('Error loading room data'));
                    }

                    final rooms = roomSnapshot.data ?? [];
                    final bookings = bookingSnapshot.data ?? [];

                    return CustomScrollView(
                      slivers: [
                        // UI Enhancement: Modern App Bar with Drawer
                        SliverAppBar(
                          expandedHeight: 120,
                          floating: false,
                          pinned: true,
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          leading: Builder(
                            builder: (context) => IconButton(
                              icon: const Icon(
                                Icons.menu,
                                color: Color(0xFF1E3A8A),
                              ),
                              onPressed: () =>
                                  Scaffold.of(context).openDrawer(),
                            ),
                          ),
                          flexibleSpace: FlexibleSpaceBar(
                            title: Text(
                              'Rooms',
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E3A8A),
                              ),
                            ),
                            centerTitle: true,
                          ),
                          actions: [
                            // UI Enhancement: Floating Add Button
                            Container(
                              margin: const EdgeInsets.only(right: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF14B8A6),
                                    Color(0xFF06B6D4),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF14B8A6,
                                    ).withValues(alpha: 0.3),
                                    offset: const Offset(0, 4),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: () => _showRoomDialog(),
                                icon: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // UI Enhancement: Stats Cards
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildStatsCard(
                                    'Total Rooms',
                                    rooms.length.toString(),
                                    Icons.bed,
                                    const Color(0xFF1E3A8A),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildStatsCard(
                                    'Available',
                                    rooms
                                        .where(
                                          (r) =>
                                              r.status.toLowerCase() ==
                                              'available',
                                        )
                                        .length
                                        .toString(),
                                    Icons.check_circle,
                                    const Color(0xFF14B8A6),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildStatsCard(
                                    'Occupied',
                                    rooms
                                        .where(
                                          (r) =>
                                              r.status.toLowerCase() ==
                                              'occupied',
                                        )
                                        .length
                                        .toString(),
                                    Icons.person,
                                    const Color(0xFFF43F5E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // UI Enhancement: Rooms Grid with Animations
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: AnimationLimiter(
                            child: SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.85,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                if (index >= rooms.length) {
                                  return const SizedBox();
                                }
                                final room = rooms[index];

                                return AnimationConfiguration.staggeredGrid(
                                  position: index,
                                  duration: const Duration(milliseconds: 500),
                                  columnCount: 2,
                                  child: SlideAnimation(
                                    verticalOffset: 50.0,
                                    child: FadeInAnimation(
                                      child: _buildRoomCard(room, bookings),
                                    ),
                                  ),
                                );
                              }, childCount: rooms.length),
                            ),
                          ),
                        ),

                        const SliverToBoxAdapter(
                          child: SizedBox(
                            height: 100,
                          ), // Space for bottom navigation
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
      // UI Enhancement: Drawer Menu
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                ),
              ),
              child: Text(
                'Resort Manager',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildDrawerItem(
              context,
              Icons.dashboard,
              'Dashboard',
              '/dashboard',
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
              Icons.attach_money_rounded,
              'Sales / Payment',
              '/sales',
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
    );
  }

  // UI Enhancement: Premium Stats Card
  Widget _buildStatsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 5),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // UI Enhancement: Luxury Room Card Design
  Widget _buildRoomCard(Room room, List<Booking> bookings) {
    final statusColor = _getStatusColor(room.status);
    final statusIcon = _getStatusIcon(room.status);

    // Get current booking for this room
    final bookingQuery = bookings
        .where((b) => b.room.number == room.number)
        .where(
          (b) =>
              DateTime.now().isAfter(b.checkIn) &&
              DateTime.now().isBefore(b.checkOut),
        );
    final currentBooking = bookingQuery.isNotEmpty ? bookingQuery.first : null;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.white.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 5),
            blurRadius: 10,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showRoomDialog(room: room),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            room.status,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showRoomDialog(room: room);
                        } else if (value == 'delete') {
                          _deleteRoom(room);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit', style: GoogleFonts.poppins()),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete', style: GoogleFonts.poppins()),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Room Number
                Text(
                  'Room ${room.number}',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),

                const SizedBox(height: 8),

                // Room Type
                Text(
                  room.type,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                  ),
                ),

                const Spacer(),

                // Current Guest (if occupied)
                if (currentBooking != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Guest',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentBooking.guest.name,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF1E293B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
