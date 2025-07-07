import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/booking.dart';
import '../models/room.dart';
import '../models/payment.dart';
import '../widgets/custom_bottom_navigation_bar.dart';

class DashboardAnalyticsScreen extends StatefulWidget {
  const DashboardAnalyticsScreen({super.key});

  @override
  State<DashboardAnalyticsScreen> createState() =>
      _DashboardAnalyticsScreenState();
}

class _DashboardAnalyticsScreenState extends State<DashboardAnalyticsScreen> {
  List<Booking> bookings = [];
  List<Room> rooms = [];
  List<Payment> payments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final bookingsBox = Hive.box<Booking>('bookings');
    final roomsBox = Hive.box<Room>('rooms');
    final paymentsBox = Hive.box<Payment>('payments');
    setState(() {
      bookings = bookingsBox.values.toList();
      rooms = roomsBox.values.toList();
      payments = paymentsBox.values.toList();
    });
  }

  // --- Data Aggregation ---
  List<BarChartGroupData> _getBookingsPerMonth() {
    final now = DateTime.now();
    final months = List.generate(
      6,
      (i) => DateTime(now.year, now.month - 5 + i, 1),
    );
    final counts = List.filled(6, 0);
    for (final b in bookings) {
      for (int i = 0; i < months.length; i++) {
        if (b.checkIn.year == months[i].year &&
            b.checkIn.month == months[i].month) {
          counts[i]++;
        }
      }
    }
    return List.generate(
      6,
      (i) => BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(toY: counts[i].toDouble(), color: Colors.blue),
        ],
      ),
    );
  }

  List<PieChartSectionData> _getRoomOccupancy() {
    int occupied = rooms
        .where((r) => r.status.toLowerCase() == 'occupied')
        .length;
    int vacant = rooms.length - occupied;
    return [
      PieChartSectionData(
        value: occupied.toDouble(),
        color: Colors.green,
        title: 'Occupied',
      ),
      PieChartSectionData(
        value: vacant.toDouble(),
        color: Colors.grey,
        title: 'Vacant',
      ),
    ];
  }

  List<FlSpot> _getRevenueTrend() {
    final now = DateTime.now();
    final months = List.generate(
      6,
      (i) => DateTime(now.year, now.month - 5 + i, 1),
    );
    final revenue = List.filled(6, 0.0);
    for (final p in payments) {
      for (int i = 0; i < months.length; i++) {
        if (p.date.year == months[i].year &&
            p.date.month == months[i].month &&
            p.status.toLowerCase() == 'paid') {
          revenue[i] += p.amount;
        }
      }
    }
    return List.generate(6, (i) => FlSpot(i.toDouble(), revenue[i]));
  }

  @override
  Widget build(BuildContext context) {
    if (!Hive.isBoxOpen('bookings') ||
        !Hive.isBoxOpen('rooms') ||
        !Hive.isBoxOpen('payments')) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final bookingsListenable = Hive.box<Booking>('bookings').listenable();
    final roomsListenable = Hive.box<Room>('rooms').listenable();
    final paymentsListenable = Hive.box<Payment>('payments').listenable();

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.blueAccent),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Analytics Dashboard',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
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
      body: ValueListenableBuilder(
        valueListenable: bookingsListenable,
        builder: (context, Box<Booking> bookingsBox, _) {
          bookings = bookingsBox.values.toList();
          return ValueListenableBuilder(
            valueListenable: roomsListenable,
            builder: (context, Box<Room> roomsBox, _) {
              rooms = roomsBox.values.toList();
              return ValueListenableBuilder(
                valueListenable: paymentsListenable,
                builder: (context, Box<Payment> paymentsBox, _) {
                  payments = paymentsBox.values.toList();
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSectionTitle('Bookings Overview'),
                      SizedBox(
                        height: 220,
                        child: Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: (bookings.isNotEmpty)
                                    ? (bookings.length / 2 + 2).toDouble()
                                    : 10,
                                barTouchData: BarTouchData(enabled: true),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: true),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final now = DateTime.now();
                                        final months = List.generate(
                                          6,
                                          (i) => DateTime(
                                            now.year,
                                            now.month - 5 + i,
                                            1,
                                          ),
                                        );
                                        return Text(
                                          '${months[value.toInt()].month}/${months[value.toInt()].year % 100}',
                                        );
                                      },
                                    ),
                                  ),
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: _getBookingsPerMonth(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Room Occupancy'),
                      SizedBox(
                        height: 220,
                        child: Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: PieChart(
                              PieChartData(
                                sections: _getRoomOccupancy(),
                                sectionsSpace: 4,
                                centerSpaceRadius: 40,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Revenue Trend'),
                      SizedBox(
                        height: 220,
                        child: Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: LineChart(
                              LineChartData(
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _getRevenueTrend(),
                                    isCurved: true,
                                    color: Colors.purple,
                                    barWidth: 4,
                                    dotData: FlDotData(show: false),
                                  ),
                                ],
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: true),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final now = DateTime.now();
                                        final months = List.generate(
                                          6,
                                          (i) => DateTime(
                                            now.year,
                                            now.month - 5 + i,
                                            1,
                                          ),
                                        );
                                        return Text(
                                          '${months[value.toInt()].month}/${months[value.toInt()].year % 100}',
                                        );
                                      },
                                    ),
                                  ),
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: 3, // 0: Dashboard, 1: Calendar, 2: Profile, 3: Analytics
        onItemTapped: (index) {
          if (index == 0) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/dashboard',
              (route) => false,
            );
          } else if (index == 1) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/calendar',
              (route) => false,
            );
          } else if (index == 2) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/profile',
              (route) => false,
            );
          } else if (index == 3) {
            // Already on analytics
          }
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
