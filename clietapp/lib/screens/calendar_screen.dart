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
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF6366F1),
                          child: Text(
                            booking.room.number,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(booking.guest.name),
                        subtitle: Text(
                          'Room ${booking.room.number} - ${booking.room.type}\n${booking.checkIn.toString().split(' ')[0]} to ${booking.checkOut.toString().split(' ')[0]}',
                        ),
                        trailing: Chip(
                          label: Text(booking.paymentStatus),
                          backgroundColor: booking.paymentStatus == 'Paid'
                              ? Colors.green.shade100
                              : Colors.orange.shade100,
                        ),
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
          _buildDrawerItem(
            Icons.attach_money_rounded,
            'Sales / Payment',
            '/sales',
          ),
          _buildDrawerItem(Icons.analytics_outlined, 'Analytics', '/analytics'),
          _buildDrawerItem(Icons.add_box_rounded, 'Booking', '/booking-form'),
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
}
