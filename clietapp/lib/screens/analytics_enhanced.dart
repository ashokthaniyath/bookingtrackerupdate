import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/booking.dart';
import '../models/room.dart';
import '../providers/resort_data_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_bottom_navigation_bar.dart';
import 'main_scaffold.dart';

class DashboardAnalyticsScreen extends StatefulWidget {
  const DashboardAnalyticsScreen({super.key});

  @override
  State<DashboardAnalyticsScreen> createState() =>
      _DashboardAnalyticsScreenState();
}

class _DashboardAnalyticsScreenState extends State<DashboardAnalyticsScreen>
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

  void _onTabSelected(int index) {
    try {
      // Debug log for navigation tracking
      print("Navigating from analytics page to index: $index");

      // Direct navigation to MainScaffold
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => MainScaffold(initialIndex: index),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Navigation error: $e');
    }
  }

  List<PieChartSectionData> _getRoomOccupancy(List<Room> rooms) {
    int occupied = rooms
        .where((r) => r.status.toLowerCase() == 'occupied')
        .length;
    int available = rooms
        .where((r) => r.status.toLowerCase() == 'available')
        .length;
    int maintenance = rooms
        .where((r) => r.status.toLowerCase() == 'maintenance')
        .length;
    int cleaning = rooms
        .where((r) => r.status.toLowerCase() == 'cleaning')
        .length;

    final total = occupied + available + maintenance + cleaning;
    if (total == 0) {
      return [
        PieChartSectionData(
          value: 1,
          color: Colors.grey.shade400,
          title: 'No Data',
          radius: 60,
          titleStyle: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ];
    }

    return [
      if (occupied > 0)
        PieChartSectionData(
          value: occupied.toDouble(),
          color: const Color(0xFFF43F5E),
          title: '$occupied',
          radius: 60,
          titleStyle: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      if (available > 0)
        PieChartSectionData(
          value: available.toDouble(),
          color: const Color(0xFF14B8A6),
          title: '$available',
          radius: 60,
          titleStyle: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      if (maintenance > 0)
        PieChartSectionData(
          value: maintenance.toDouble(),
          color: const Color(0xFF6B7280),
          title: '$maintenance',
          radius: 60,
          titleStyle: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      if (cleaning > 0)
        PieChartSectionData(
          value: cleaning.toDouble(),
          color: const Color(0xFFEAB308),
          title: '$cleaning',
          radius: 60,
          titleStyle: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
    ];
  }

  List<Widget> _buildPieChartLegend(List<Room> rooms) {
    int occupied = rooms
        .where((r) => r.status.toLowerCase() == 'occupied')
        .length;
    int available = rooms
        .where((r) => r.status.toLowerCase() == 'available')
        .length;
    int maintenance = rooms
        .where((r) => r.status.toLowerCase() == 'maintenance')
        .length;
    int cleaning = rooms
        .where((r) => r.status.toLowerCase() == 'cleaning')
        .length;

    return [
      if (occupied > 0)
        _buildLegendItem('Occupied', occupied, const Color(0xFFF43F5E)),
      if (available > 0)
        _buildLegendItem('Available', available, const Color(0xFF14B8A6)),
      if (maintenance > 0)
        _buildLegendItem('Maintenance', maintenance, const Color(0xFF6B7280)),
      if (cleaning > 0)
        _buildLegendItem('Cleaning', cleaning, const Color(0xFFEAB308)),
    ];
  }

  Widget _buildLegendItem(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label ($count)',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _getRevenueTrend(List<Booking> bookings) {
    final now = DateTime.now();
    final months = List.generate(
      6,
      (i) => DateTime(now.year, now.month - 5 + i, 1),
    );
    final revenue = List.filled(6, 0.0);

    // Calculate revenue from paid bookings (assuming ₹1500 per booking)
    for (final b in bookings) {
      if (b.paymentStatus.toLowerCase() == 'paid') {
        for (int i = 0; i < months.length; i++) {
          if (b.checkIn.year == months[i].year &&
              b.checkIn.month == months[i].month) {
            revenue[i] += 1500.0; // Base rate
          }
        }
      }
    }

    return List.generate(
      6,
      (i) => FlSpot(i.toDouble(), revenue[i] / 1000), // Convert to thousands
    );
  }

  double _getOccupancyRate(List<Room> rooms) {
    if (rooms.isEmpty) return 0.0;
    final occupied = rooms
        .where((r) => r.status.toLowerCase() == 'occupied')
        .length;
    return (occupied / rooms.length) * 100;
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    String route,
  ) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1E3A8A)),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
      ),
      onTap: () {
        Navigator.pop(context);
        if (ModalRoute.of(context)?.settings.name != route) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Data Flow: Use Consumer to listen to provider changes for real-time analytics
    return Consumer<ResortDataProvider>(
      builder: (context, provider, child) {
        return Container(
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
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Color(0xFF1E3A8A)),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              title: Text(
                'Analytics',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E3A8A),
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF1E3A8A)),
                  onPressed: () {
                    // Data is automatically updated via provider
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Data is synced in real-time!'),
                      ),
                    );
                  },
                ),
              ],
            ),
            body: FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                slivers: [
                  // Key Metrics Cards
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricCard(
                                  'Occupancy Rate',
                                  '${_getOccupancyRate(provider.rooms).toStringAsFixed(1)}%',
                                  Icons.hotel,
                                  const LinearGradient(
                                    colors: [
                                      Color(0xFF1E3A8A),
                                      Color(0xFF3B82F6),
                                    ],
                                  ),
                                  _getOccupancyRate(provider.rooms) > 80
                                      ? 'High occupancy'
                                      : _getOccupancyRate(provider.rooms) > 50
                                      ? 'Moderate occupancy'
                                      : 'Low occupancy',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildMetricCard(
                                  'Total Bookings',
                                  provider.bookings.length.toString(),
                                  Icons.book_online,
                                  const LinearGradient(
                                    colors: [
                                      Color(0xFF14B8A6),
                                      Color(0xFF059669),
                                    ],
                                  ),
                                  'All time',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricCard(
                                  'Available Rooms',
                                  provider.availableRooms.toString(),
                                  Icons.bed,
                                  const LinearGradient(
                                    colors: [
                                      Color(0xFFEAB308),
                                      Color(0xFFD97706),
                                    ],
                                  ),
                                  'Ready for booking',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildMetricCard(
                                  'Revenue This Month',
                                  '₹${NumberFormat('#,##,###').format(provider.totalRevenue)}',
                                  Icons.trending_up,
                                  const LinearGradient(
                                    colors: [
                                      Color(0xFFF43F5E),
                                      Color(0xFFEC4899),
                                    ],
                                  ),
                                  'Paid bookings',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Charts Section
                  SliverToBoxAdapter(
                    child: AnimationLimiter(
                      child: Column(
                        children: AnimationConfiguration.toStaggeredList(
                          duration: const Duration(milliseconds: 500),
                          childAnimationBuilder: (widget) => SlideAnimation(
                            horizontalOffset: 50.0,
                            child: FadeInAnimation(child: widget),
                          ),
                          children: [
                            // Room Occupancy Pie Chart - FIXED LAYOUT
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Room Status Distribution',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  // FIXED: Proper responsive layout for pie chart
                                  SizedBox(
                                    height: 250,
                                    child: Row(
                                      children: [
                                        // Pie chart - Fixed aspect ratio
                                        Expanded(
                                          flex: 3,
                                          child: AspectRatio(
                                            aspectRatio: 1.0,
                                            child: PieChart(
                                              PieChartData(
                                                sections: _getRoomOccupancy(
                                                  provider.rooms,
                                                ),
                                                borderData: FlBorderData(
                                                  show: false,
                                                ),
                                                sectionsSpace: 2,
                                                centerSpaceRadius: 40,
                                                pieTouchData: PieTouchData(
                                                  enabled: false,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        // Legend - Fixed layout
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: _buildPieChartLegend(
                                              provider.rooms,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Revenue Trend Line Chart
                            Container(
                              margin: const EdgeInsets.all(20),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Revenue Trend (₹ in thousands)',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    height: 200,
                                    child: LineChart(
                                      LineChartData(
                                        gridData: const FlGridData(show: true),
                                        titlesData: FlTitlesData(
                                          leftTitles: const AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                            ),
                                          ),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              getTitlesWidget: (value, meta) {
                                                final now = DateTime.now();
                                                final month = DateTime(
                                                  now.year,
                                                  now.month - 5 + value.toInt(),
                                                  1,
                                                );
                                                return Text(
                                                  DateFormat(
                                                    'MMM',
                                                  ).format(month),
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    color: const Color(
                                                      0xFF64748B,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          rightTitles: const AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: false,
                                            ),
                                          ),
                                          topTitles: const AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: false,
                                            ),
                                          ),
                                        ),
                                        borderData: FlBorderData(show: false),
                                        lineBarsData: [
                                          LineChartBarData(
                                            spots: _getRevenueTrend(
                                              provider.bookings,
                                            ),
                                            isCurved: true,
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFF1E3A8A),
                                                Color(0xFF3B82F6),
                                              ],
                                            ),
                                            barWidth: 4,
                                            isStrokeCapRound: true,
                                            dotData: const FlDotData(
                                              show: true,
                                            ),
                                            belowBarData: BarAreaData(
                                              show: true,
                                              gradient: LinearGradient(
                                                colors: [
                                                  const Color(
                                                    0xFF1E3A8A,
                                                  ).withValues(alpha: 0.3),
                                                  const Color(
                                                    0xFF1E3A8A,
                                                  ).withValues(alpha: 0.1),
                                                ],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100), // Space for bottom navigation
                  ),
                ],
              ),
            ),
            // Drawer Menu
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
                  _buildDrawerItem(
                    context,
                    Icons.bed_rounded,
                    'Rooms',
                    '/rooms',
                  ),
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
                    Icons.person_outline,
                    'Profile',
                    '/profile',
                  ),
                ],
              ),
            ),
            bottomNavigationBar: CustomBottomNavigation(
              selectedIndex:
                  1, // Analytics are typically index 1 (adjust as needed for your app structure)
              onItemTapped: _onTabSelected,
            ),
          ),
        );
      },
    );
  }

  // Premium Metric Card
  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Gradient gradient,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
