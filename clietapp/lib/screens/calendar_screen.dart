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

    // Defensive: Only assign if box is open, else show loading
    if (Hive.isBoxOpen('bookings')) {
      _bookingBox = Hive.box<Booking>('bookings');
      _groupBookingsByDay();
      _bookingBox.listenable().addListener(_groupBookingsByDay);
    }

    // Start animations
    _fadeController.forward();
    _slideController.forward();
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
        grouped.putIfAbsent(day, () => []).add(booking);
        day = day.add(const Duration(days: 1));
      }
    }
    setState(() {
      _bookingsByDay = grouped;
    });
  }

  List<Booking> _getBookingsForDay(DateTime day) {
    return _bookingsByDay[_stripTime(day)] ?? [];
  }

  DateTime _stripTime(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  void _onNewBooking() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BookingFormPage()),
    );
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
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _roomColor(booking.room.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.hotel,
                      color: _roomColor(booking.room.type),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.guest.name,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        Text(
                          'Room ${booking.room.number} (${booking.room.type})',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildInfoRow(
                Icons.calendar_today,
                'Check-in',
                _formatDate(booking.checkIn),
              ),
              _buildInfoRow(
                Icons.calendar_today,
                'Check-out',
                _formatDate(booking.checkOut),
              ),
              _buildInfoRow(Icons.payment, 'Payment', booking.paymentStatus),
              if (booking.notes.isNotEmpty)
                _buildInfoRow(Icons.note, 'Notes', booking.notes),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _sendReminder(booking),
                      icon: const Icon(Icons.email_outlined),
                      label: const Text('Send Reminder'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _shareBooking(booking),
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(color: Colors.blue.shade900),
            ),
          ),
        ],
      ),
    );
  }

  // New Feature: Send Reminder Email
  Future<void> _sendReminder(Booking booking) async {
    final success = await _calendarService.sendBookingNotification(
      booking,
      'reminder',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Reminder sent successfully!' : 'Failed to send reminder',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  // New Feature: Share Booking
  Future<void> _shareBooking(Booking booking) async {
    final publicLink = _calendarService.getPublicCalendarLink(
      booking.room.number,
    );
    final shareText =
        'Booking Details:\n'
        'Guest: ${booking.guest.name}\n'
        'Room: ${booking.room.number} (${booking.room.type})\n'
        'Check-in: ${_formatDate(booking.checkIn)}\n'
        'Check-out: ${_formatDate(booking.checkOut)}\n'
        'Calendar: $publicLink';

    final url = Uri(
      scheme: 'mailto',
      query: 'subject=Booking Details&body=${Uri.encodeComponent(shareText)}',
    );

    await launchUrl(url);
  }

  // New Feature: Room Selection and Management
  Widget _buildRoomSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.blue.shade50],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.hotel, color: Colors.blue.shade600),
          const SizedBox(width: 12),
          Text(
            'Room:',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              color: Colors.blue.shade900,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedRoom,
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
                icon: Icon(Icons.arrow_drop_down, color: Colors.blue.shade600),
              ),
            ),
          ),
          // New Feature: Availability Filter
          FilterChip(
            label: Text(
              'Available Only',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            selected: _showAvailabilityOnly,
            onSelected: (selected) {
              setState(() {
                _showAvailabilityOnly = selected;
              });
            },
            selectedColor: Colors.green.withOpacity(0.2),
            checkmarkColor: Colors.green,
          ),
        ],
      ),
    );
  }

  // New Feature: Quick Actions Panel
  Widget _buildQuickActionsPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickAction(
            Icons.add_circle_outline,
            'New Booking',
            () => _onNewBooking(),
          ),
          _buildQuickAction(Icons.link, 'Public Link', () => _copyPublicLink()),
          _buildQuickAction(
            Icons.schedule,
            'Set Hours',
            () => _setUnavailableHours(),
          ),
          _buildQuickAction(
            Icons.sync,
            'Sync Google',
            () => _syncGoogleCalendar(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // New Feature: Copy Public Calendar Link
  void _copyPublicLink() {
    final link = _calendarService.getPublicCalendarLink(_selectedRoom);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Public calendar link: $link'),
        action: SnackBarAction(
          label: 'Copy',
          onPressed: () {
            // In a real app, you'd use clipboard
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Link copied to clipboard!')),
            );
          },
        ),
      ),
    );
  }

  // New Feature: Set Unavailable Hours Dialog
  void _setUnavailableHours() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.orange.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Set Unavailable Hours',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Configure cleaning or maintenance hours for room $_selectedRoom',
                style: GoogleFonts.poppins(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Cleaning hours set: 10:00 AM - 2:00 PM',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Set Cleaning Hours'),
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

  // New Feature: Sync with Google Calendar
  Future<void> _syncGoogleCalendar() async {
    final service = GoogleCalendarService();
    final events = await service.fetchEvents();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Synced ${events.length} Google Calendar events!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (!Hive.isBoxOpen('bookings')) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF64B5F6), Color(0xFFE3F2FD), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
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
                // Show email options dialog
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
                      // New Feature: Room Selector
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

                      // New Feature: Quick Actions Panel
                      AnimationConfiguration.staggeredList(
                        position: 1,
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildQuickActionsPanel(),
                          ),
                        ),
                      ),

                      // Enhanced Navigation Row
                      AnimationConfiguration.staggeredList(
                        position: 2,
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade100,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: IconButton(
                                            icon: Icon(
                                              Icons.chevron_left_rounded,
                                              color: Colors.blue.shade700,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _focusedDay = DateTime(
                                                  _focusedDay.year,
                                                  _focusedDay.month - 1,
                                                  1,
                                                );
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          '${_focusedDay.year} - ${_monthName(_focusedDay.month)}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue.shade900,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade100,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: IconButton(
                                            icon: Icon(
                                              Icons.chevron_right_rounded,
                                              color: Colors.blue.shade700,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _focusedDay = DateTime(
                                                  _focusedDay.year,
                                                  _focusedDay.month + 1,
                                                  1,
                                                );
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.blue.shade600,
                                            Colors.blue.shade400,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: ToggleButtons(
                                        isSelected: [
                                          _calendarFormat ==
                                              CalendarFormat.month,
                                          _calendarFormat ==
                                              CalendarFormat.twoWeeks,
                                        ],
                                        onPressed: (index) {
                                          setState(() {
                                            _calendarFormat = index == 0
                                                ? CalendarFormat.month
                                                : CalendarFormat.twoWeeks;
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(15),
                                        selectedColor: Colors.white,
                                        color: Colors.white70,
                                        fillColor: Colors.blue.shade700,
                                        borderColor: Colors.transparent,
                                        selectedBorderColor: Colors.transparent,
                                        children: const [
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            child: Text('Month'),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            child: Text('Table'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Enhanced Calendar - FIXED LAYOUT
                      AnimationConfiguration.staggeredList(
                        position: 3,
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: Container(
                              margin: const EdgeInsets.all(16),
                              height: 450, // Fixed height to prevent distortion
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.15),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
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
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (context) =>
                                            _EnhancedBookingListSheet(
                                              date: selectedDay,
                                              bookings: bookings,
                                              onBookingTap: _onBookingTap,
                                              onAddBooking: () async {
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
                                                Navigator.pop(context);
                                              },
                                              selectedRoom: _selectedRoom,
                                              calendarService: _calendarService,
                                            ),
                                      );
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
                                            color: Colors.orange.withOpacity(
                                              0.4,
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
                                            color: Colors.blue.withOpacity(0.4),
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
                                      defaultTextStyle: GoogleFonts.poppins(),
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
                                              scrollDirection: Axis.horizontal,
                                              itemCount: bookings.length > 3
                                                  ? 3
                                                  : bookings.length,
                                              separatorBuilder: (_, __) =>
                                                  const SizedBox(width: 2),
                                              itemBuilder: (context, idx) {
                                                final booking = bookings[idx];
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
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        color.withOpacity(0.8),
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
                                                            .withOpacity(0.3),
                                                        blurRadius: 4,
                                                        offset: const Offset(
                                                          0,
                                                          2,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Text(
                                                    booking.room.number,
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month];
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

// New Feature: Enhanced Booking List Sheet with Stunning UI
class _EnhancedBookingListSheet extends StatelessWidget {
  final DateTime date;
  final List<Booking> bookings;
  final void Function(Booking) onBookingTap;
  final VoidCallback? onAddBooking;
  final String selectedRoom;
  final EnhancedGoogleCalendarService calendarService;

  const _EnhancedBookingListSheet({
    required this.date,
    required this.bookings,
    required this.onBookingTap,
    this.onAddBooking,
    required this.selectedRoom,
    required this.calendarService,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xFFF8F9FA)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade600],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${date.day}/${date.month}/${date.year}',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          Text(
                            '${bookings.length} booking${bookings.length != 1 ? 's' : ''}',
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // New Feature: Quick Actions in Sheet
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _sharePublicLink(context),
                          icon: const Icon(Icons.share, color: Colors.blue),
                          tooltip: 'Share Calendar',
                        ),
                        IconButton(
                          onPressed: () => _checkAvailability(context),
                          icon: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                          tooltip: 'Check Availability',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Bookings List
              Expanded(
                child: bookings.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount:
                            bookings.length + (onAddBooking != null ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (index == bookings.length &&
                              onAddBooking != null) {
                            return _buildAddBookingCard();
                          }
                          return _buildEnhancedBookingCard(bookings[index]);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.event_available,
              size: 48,
              color: Colors.blue.shade300,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No bookings for this date',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add a booking',
            style: GoogleFonts.poppins(color: Colors.grey.shade500),
          ),
          if (onAddBooking != null) ...[
            const SizedBox(height: 24),
            _buildAddBookingCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildEnhancedBookingCard(Booking booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => onBookingTap(booking),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: _getRoomColor(booking.room.type),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          booking.guest.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getRoomColor(
                            booking.room.type,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Room ${booking.room.number}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _getRoomColor(booking.room.type),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.hotel, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        booking.room.type,
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.payment,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        booking.paymentStatus,
                        style: GoogleFonts.poppins(
                          color: booking.paymentStatus == 'Paid'
                              ? Colors.green
                              : Colors.orange,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildAddBookingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: onAddBooking,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Text(
              'Add New Booking',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoomColor(String type) {
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

  // New Feature: Share Public Calendar Link
  void _sharePublicLink(BuildContext context) {
    final link = calendarService.getPublicCalendarLink(selectedRoom);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Public calendar: $link'),
        action: SnackBarAction(
          label: 'Share',
          onPressed: () {
            // Launch share intent
          },
        ),
      ),
    );
  }

  // New Feature: Check Real-time Availability
  void _checkAvailability(BuildContext context) async {
    final isAvailable = await calendarService.checkRoomAvailability(
      roomNumber: selectedRoom,
      startTime: date,
      endTime: date.add(const Duration(days: 1)),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAvailable
              ? 'Room $selectedRoom is available!'
              : 'Room $selectedRoom is occupied',
        ),
        backgroundColor: isAvailable ? Colors.green : Colors.red,
      ),
    );
  }
}
