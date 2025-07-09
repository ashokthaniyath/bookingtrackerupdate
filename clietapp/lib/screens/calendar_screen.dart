import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/booking.dart';
import '../utils/google_calendar_service.dart';
import 'booking_form.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with TickerProviderStateMixin {
  late final Box<Booking> _bookingBox;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  Map<DateTime, List<Booking>> _bookingsByDay = {};

  // New Feature: Room Calendar Management
  late final EnhancedGoogleCalendarService _calendarService;
  String _selectedRoom = 'All Rooms';
  final List<String> _availableRooms = [
    'All Rooms',
    '101',
    '102',
    '103',
    '201',
    '202',
    '203',
  ];
  bool _showAvailabilityOnly = false;

  // UI Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );

    // Initialize calendar service
    _calendarService = EnhancedGoogleCalendarService();
    _calendarService.initializeRoomCalendars();

    // Use addPostFrameCallback to ensure widget is laid out before accessing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Defensive: Only assign if box is open, else show loading
        if (Hive.isBoxOpen('bookings')) {
          _bookingBox = Hive.box<Booking>('bookings');
          _groupBookingsByDay();
          _bookingBox.listenable().addListener(_groupBookingsByDay);
        }

        // Start animations after layout is complete
        _fadeController.forward();
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _groupBookingsByDay() {
    final Map<DateTime, List<Booking>> grouped = {};
    final bookings = _selectedRoom == 'All Rooms'
        ? _bookingBox.values
        : _bookingBox.values.where((b) => b.room.number == _selectedRoom);

    for (final booking in bookings) {
      DateTime day = _stripTime(booking.checkIn);
      final end = _stripTime(booking.checkOut);
      while (!day.isAfter(end)) {
        if (grouped[day] == null) grouped[day] = [];
        grouped[day]!.add(booking);
        day = day.add(const Duration(days: 1));
      }
    }
    if (mounted) {
      setState(() {
        _bookingsByDay = grouped;
      });
    }
  }

  List<Booking> _getBookingsForDay(DateTime day) {
    return _bookingsByDay[_stripTime(day)] ?? [];
  }

  DateTime _stripTime(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  void _onNewBooking() async {
    // Ensure layout is complete before navigation
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted && context.mounted) {
        try {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BookingFormPage()),
          );
        } catch (e) {
          debugPrint('Navigation error: $e');
        }
      }
    });
  }

  void _onBookingTap(Booking booking) {
    _showBookingDetailsDialog(booking);
  }

  // New Feature: Enhanced Booking Details Dialog
  void _showBookingDetailsDialog(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.blue.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with luxury icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.blue.shade800],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.hotel_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Booking Details',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              const SizedBox(height: 20),

              _buildInfoRow(Icons.person_rounded, 'Guest', booking.guest.name),
              _buildInfoRow(
                Icons.hotel_rounded,
                'Room',
                '${booking.room.number} (${booking.room.type})',
              ),
              _buildInfoRow(Icons.payment, 'Payment', booking.paymentStatus),
              if (booking.notes.isNotEmpty)
                _buildInfoRow(Icons.note, 'Notes', booking.notes),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: Text(
                      'Close',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to edit booking
                    },
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: Text(
                      'Edit',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue.shade700, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoomSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.meeting_room_rounded,
              color: Colors.blue.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedRoom,
              decoration: InputDecoration(
                labelText: 'Room Filter',
                labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade600),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: _availableRooms.map((room) {
                return DropdownMenuItem(
                  value: room,
                  child: Text(room, style: GoogleFonts.poppins()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRoom = value!;
                  _groupBookingsByDay();
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: () {
                setState(() {
                  _showAvailabilityOnly = !_showAvailabilityOnly;
                  _groupBookingsByDay();
                });
              },
              icon: Icon(
                _showAvailabilityOnly ? Icons.visibility_off : Icons.visibility,
                color: Colors.blue.shade700,
              ),
              tooltip: _showAvailabilityOnly
                  ? 'Show All Dates'
                  : 'Show Available Only',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickAction(
            Icons.add_circle_outline,
            'New Booking',
            _onNewBooking,
          ),
          _buildQuickAction(Icons.link, 'Public Link', () => _copyPublicLink()),
          _buildQuickAction(
            Icons.email_outlined,
            'Send Email',
            () => _sendReminderEmail(),
          ),
          _buildQuickAction(
            Icons.analytics_outlined,
            'Analytics',
            () => _showAnalytics(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.blue.shade700, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyPublicLink() {
    // Implementation for copying public calendar link
    debugPrint('Copying public calendar link');
  }

  void _sendReminderEmail() {
    // Implementation for sending reminder email
    debugPrint('Sending reminder email');
  }

  void _showAnalytics() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.blue.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.analytics_rounded,
                color: Colors.blue.shade700,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Calendar Analytics',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Total Bookings: ${_bookingBox.length}',
                style: GoogleFonts.poppins(),
              ),
              Text('Occupancy Rate: 75%', style: GoogleFonts.poppins()),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close', style: GoogleFonts.poppins()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ensure proper initialization before rendering
    if (!Hive.isBoxOpen('bookings') ||
        !mounted ||
        (!_fadeController.isCompleted && !_fadeController.isAnimating)) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF64B5F6), Color(0xFFE3F2FD), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const SafeArea(
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFF14B8A6)),
          ),
        ),
      );
    }

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF64B5F6), Color(0xFFE3F2FD), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'Resort Calendar',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                  fontSize: 26,
                ),
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.link, color: Colors.blueAccent),
                tooltip: 'Copy Public Calendar Link',
                onPressed: _copyPublicLink,
              ),
              IconButton(
                icon: const Icon(Icons.email_outlined, color: Colors.teal),
                tooltip: 'Send Reminder Email',
                onPressed: () async {
                  final emailUrl = Uri(
                    scheme: 'mailto',
                    query:
                        'subject=Resort Booking Reminder&body=Dear Guest, this is a reminder about your upcoming reservation.',
                  );
                  await launchUrl(emailUrl);
                },
              ),
            ],
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ValueListenableBuilder(
                valueListenable: _bookingBox.listenable(),
                builder: (context, Box<Booking> box, _) {
                  return AnimationLimiter(
                    child: Column(
                      children: [
                        // Room Selector
                        AnimationConfiguration.staggeredList(
                          position: 0,
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: _buildRoomSelector(),
                              ),
                            ),
                          ),
                        ),

                        // Quick Actions Panel
                        AnimationConfiguration.staggeredList(
                          position: 1,
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _buildQuickActionsPanel(),
                            ),
                          ),
                        ),

                        // Calendar
                        Expanded(
                          child: AnimationConfiguration.staggeredList(
                            position: 2,
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: Container(
                                  margin: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.08,
                                        ),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(25),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: TableCalendar<Booking>(
                                        firstDay: DateTime.utc(2020, 1, 1),
                                        lastDay: DateTime.utc(2030, 12, 31),
                                        focusedDay: _focusedDay,
                                        calendarFormat: _calendarFormat,
                                        selectedDayPredicate: (day) =>
                                            isSameDay(_selectedDay, day),
                                        onDaySelected: (selectedDay, focusedDay) {
                                          setState(() {
                                            _selectedDay = selectedDay;
                                            _focusedDay = focusedDay;
                                          });
                                          final bookings = _getBookingsForDay(
                                            selectedDay,
                                          );
                                          if (bookings.isNotEmpty) {
                                            showModalBottomSheet(
                                              context: context,
                                              isScrollControlled: true,
                                              backgroundColor:
                                                  Colors.transparent,
                                              builder: (context) => _EnhancedBookingListSheet(
                                                date: selectedDay,
                                                bookings: bookings,
                                                onBookingTap: _onBookingTap,
                                                onAddBooking: () async {
                                                  // Ensure layout is complete before navigation
                                                  WidgetsBinding.instance.addPostFrameCallback((
                                                    _,
                                                  ) async {
                                                    if (mounted &&
                                                        context.mounted) {
                                                      try {
                                                        await Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                BookingFormPage(
                                                                  initialDate:
                                                                      selectedDay,
                                                                ),
                                                          ),
                                                        );
                                                        if (mounted &&
                                                            context.mounted) {
                                                          Navigator.pop(
                                                            context,
                                                          );
                                                        }
                                                      } catch (e) {
                                                        debugPrint(
                                                          'Navigation error: $e',
                                                        );
                                                      }
                                                    }
                                                  });
                                                },
                                                selectedRoom: _selectedRoom,
                                                calendarService:
                                                    _calendarService,
                                              ),
                                            );
                                          }
                                        },
                                        eventLoader: _getBookingsForDay,
                                        calendarStyle: CalendarStyle(
                                          todayDecoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.orange.shade400,
                                                Colors.orange.shade600,
                                              ],
                                            ),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.orange.withValues(
                                                  alpha: 0.4,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          selectedDecoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.blue.shade500,
                                                Colors.blue.shade700,
                                              ],
                                            ),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.blue.withValues(
                                                  alpha: 0.4,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          markerDecoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.teal.shade400,
                                                Colors.teal.shade600,
                                              ],
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          outsideDaysVisible: false,
                                          weekendTextStyle: GoogleFonts.poppins(
                                            color: Colors.red.shade400,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          defaultTextStyle:
                                              GoogleFonts.poppins(),
                                        ),
                                        headerVisible: false,
                                        calendarBuilders: CalendarBuilders(
                                          markerBuilder: (context, date, bookings) {
                                            if (bookings.isEmpty) return null;
                                            return Positioned(
                                              bottom: 1,
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 300,
                                                ),
                                                height: 32,
                                                child: ListView.separated(
                                                  shrinkWrap: true,
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  itemCount: bookings.length > 3
                                                      ? 3
                                                      : bookings.length,
                                                  separatorBuilder: (_, __) =>
                                                      const SizedBox(width: 2),
                                                  itemBuilder: (context, idx) {
                                                    final booking =
                                                        bookings[idx];
                                                    final color = _roomColor(
                                                      booking.room.type,
                                                    );
                                                    return Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            LinearGradient(
                                                              colors: [
                                                                color
                                                                    .withValues(
                                                                      alpha:
                                                                          0.8,
                                                                    ),
                                                                color,
                                                              ],
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: color
                                                                .withValues(
                                                                  alpha: 0.3,
                                                                ),
                                                            blurRadius: 4,
                                                            offset:
                                                                const Offset(
                                                                  0,
                                                                  2,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Text(
                                                        booking.room.number,
                                                        style:
                                                            GoogleFonts.poppins(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 10,
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _roomColor(String type) {
    switch (type.toLowerCase()) {
      case 'deluxe':
        return Colors.blueAccent;
      case 'single':
        return Colors.green;
      case 'double':
        return Colors.orange;
      case 'suite':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

// Enhanced Booking List Sheet Widget
class _EnhancedBookingListSheet extends StatelessWidget {
  final DateTime date;
  final List<Booking> bookings;
  final Function(Booking) onBookingTap;
  final VoidCallback onAddBooking;
  final String selectedRoom;
  final EnhancedGoogleCalendarService calendarService;

  const _EnhancedBookingListSheet({
    required this.date,
    required this.bookings,
    required this.onBookingTap,
    required this.onAddBooking,
    required this.selectedRoom,
    required this.calendarService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Color(0xFFF0F9FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 50,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Bookings for',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
          ),

          // Add Booking Button
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAddBooking,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Add New Booking',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Bookings List
          Expanded(
            child: bookings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No bookings for this date',
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          onTap: () => onBookingTap(booking),
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.hotel_rounded,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          title: Text(
                            booking.guest.name,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          subtitle: Text(
                            'Room ${booking.room.number} • ${booking.room.type}',
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                booking.paymentStatus,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              booking.paymentStatus,
                              style: GoogleFonts.poppins(
                                color: _getStatusColor(booking.paymentStatus),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
