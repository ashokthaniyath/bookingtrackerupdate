import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/booking.dart';
import '../providers/resort_data_provider.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(),
      body: Consumer<ResortDataProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              TableCalendar<Booking>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: (day) => _getEventsForDay(provider.bookings, day),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isEmpty) return null;

                    // Check if any booking on this day is AI-created
                    final hasAIBooking = events.any(
                      (booking) =>
                          booking.notes.contains('Created by AI Assistant'),
                    );

                    return Positioned(
                      bottom: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (hasAIBooking) ...[
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 1),
                          ],
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF6366F1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                calendarStyle: const CalendarStyle(
                  outsideDaysVisible: false,
                  weekendTextStyle: TextStyle(color: Colors.red),
                  holidayTextStyle: TextStyle(color: Colors.red),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonShowsNext: false,
                  formatButtonDecoration: BoxDecoration(
                    color: Color(0xFF6366F1),
                    borderRadius: BorderRadius.all(Radius.circular(12.0)),
                  ),
                  formatButtonTextStyle: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              // Daily booking summary
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildDayBookingSummary(provider),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _getEventsForDay(
                    provider.bookings,
                    _selectedDay,
                  ).length,
                  itemBuilder: (context, index) {
                    final booking = _getEventsForDay(
                      provider.bookings,
                      _selectedDay,
                    )[index];

                    // Check if this is an AI-created booking
                    final isAIBooking = booking.notes.contains(
                      'Created by AI Assistant',
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Stack(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isAIBooking
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF6366F1),
                              child: isAIBooking
                                  ? const Icon(
                                      Icons.smart_toy,
                                      color: Colors.white,
                                      size: 18,
                                    )
                                  : Text(
                                      booking.room.number,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                            title: Row(
                              children: [
                                Expanded(child: Text(booking.guest.name)),
                                if (isAIBooking) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF10B981),
                                          Color(0xFF059669),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'AI',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Text(
                              'Room ${booking.room.number} - ${booking.room.type}\n${booking.checkIn.toString().split(' ')[0]} to ${booking.checkOut.toString().split(' ')[0]}${isAIBooking ? '\n✨ Created by AI Assistant' : ''}',
                            ),
                            trailing: Chip(
                              label: Text(booking.paymentStatus),
                              backgroundColor: booking.paymentStatus == 'Paid'
                                  ? Colors.green.shade100
                                  : Colors.orange.shade100,
                            ),
                          ),
                          if (isAIBooking)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.auto_awesome,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Booking> _getEventsForDay(List<Booking> bookings, DateTime day) {
    return bookings.where((booking) {
      return (booking.checkIn.isBefore(day.add(const Duration(days: 1))) &&
              booking.checkOut.isAfter(day)) ||
          isSameDay(booking.checkIn, day) ||
          isSameDay(booking.checkOut, day);
    }).toList();
  }

  // UI Enhancement: Modern Drawer
  Widget _buildDrawer() {
    return Drawer(
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
          _buildDrawerItem(Icons.dashboard, 'Dashboard', '/dashboard'),
          _buildDrawerItem(Icons.bed_rounded, 'Rooms', '/rooms'),
          _buildDrawerItem(Icons.people_alt_rounded, 'Guest List', '/guests'),
          _buildDrawerItem(Icons.analytics_outlined, 'Analytics', '/analytics'),
          _buildDrawerItem(Icons.person_outline, 'Profile', '/profile'),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1E3A8A)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: () {
        Navigator.pop(context);
        if (ModalRoute.of(context)?.settings.name != route) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }

  // Build daily booking summary widget
  Widget _buildDayBookingSummary(ResortDataProvider provider) {
    final dayBookings = _getEventsForDay(provider.bookings, _selectedDay);
    final aiBookings = dayBookings
        .where((b) => b.notes.contains('Created by AI Assistant'))
        .length;
    final totalBookings = dayBookings.length;

    if (totalBookings == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.grey.shade400),
            const SizedBox(width: 12),
            Text(
              'No bookings for ${_selectedDay.toString().split(' ')[0]}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_selectedDay.toString().split(' ')[0]} Summary',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildSummaryItem(
                      'Total',
                      totalBookings.toString(),
                      Icons.event,
                    ),
                    const SizedBox(width: 20),
                    _buildSummaryItem(
                      'AI Created',
                      aiBookings.toString(),
                      Icons.smart_toy,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (aiBookings > 0)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }
}
