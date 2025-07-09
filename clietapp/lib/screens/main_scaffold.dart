import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/custom_bottom_navigation_bar.dart';
import 'home_dashboard_screen.dart';
import 'calendar_screen.dart';
import 'invoices_screen.dart';
import 'booking_form.dart';

class MainScaffold extends StatefulWidget {
  final int initialIndex;
  const MainScaffold({super.key, this.initialIndex = 0});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  // Fix: Reconfigured screens - Core 4 pages for bottom nav
  final List<Widget> _screens = [
    const HomeDashboardScreen(), // Index 0: Home
    const CalendarScreen(), // Index 1: Calendar
    const InvoicesScreen(), // Index 2: Invoices
    const BookingFormPage(), // Index 3: Booking
  ];
  void _onTabSelected(int index) {
    if (_currentIndex == index) return;

    // Debug log for navigation tracking
    print("Navigating to index: $index");

    // Bug Prevention: PostFrameCallback for safe navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          setState(() {
            _currentIndex = index;
          });
        }
      });
    });
  }

  // Get page title based on current index
  String _getPageTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Home Dashboard';
      case 1:
        return 'Calendar';
      case 2:
        return 'Invoices & Billing';
      case 3:
        return 'Create Booking';
      default:
        return 'Resort Management';
    }
  }

  // Build drawer for secondary navigation
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3A8A), // Deep blue
              Color(0xFF3B82F6), // Lighter blue
            ],
          ),
        ),
        child: Column(
          children: [
            // Drawer Header
            Container(
              height: 200,
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Icon(
                      Icons.hotel,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Resort Management',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Tuesday, July 8, 2025',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            // Drawer Items
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Secondary Navigation',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildDrawerItem(
                      context,
                      icon: Icons.bed_outlined,
                      title: 'Rooms',
                      subtitle: 'Room Management',
                      route: '/rooms',
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.people_outline,
                      title: 'Guest List',
                      subtitle: 'Guest Management',
                      route: '/guests',
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.payment_outlined,
                      title: 'Sales & Payment',
                      subtitle: 'Payment Management',
                      route: '/payment',
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.analytics_outlined,
                      title: 'Analytics',
                      subtitle: 'Performance Analytics',
                      route: '/analytics',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.grey.shade50,
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF14B8A6), size: 24),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Color(0xFF14B8A6),
        ),
        onTap: () {
          // Bug Prevention: PostFrameCallback for safe navigation
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pop(context); // Close drawer first
            print("Navigating to $title via route: $route");
            Navigator.pushNamed(context, route);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      // Fix: Added Drawer for secondary navigation
      drawer: _buildDrawer(context),
      appBar: _currentIndex == 3
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Color(0xFF1E3A8A)),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              title: Text(
                _getPageTitle(),
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E3A8A),
                ),
              ),
              centerTitle: true,
            ),
      body: Container(
        // UI Enhancement: Luxury Gradient Background
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
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          child: IndexedStack(
            key: ValueKey(_currentIndex),
            index: _currentIndex,
            children: _screens,
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: _currentIndex,
        onItemTapped: _onTabSelected,
      ),
    );
  }
}
