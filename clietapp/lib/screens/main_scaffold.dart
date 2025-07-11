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

    // Direct state update for immediate navigation
    if (mounted) {
      setState(() {
        _currentIndex = index;
      });
    }
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
            icon: Icons.dashboard,
            title: 'Dashboard',
            subtitle: 'Main Dashboard',
            route: '/dashboard',
          ),
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
          _buildDrawerItem(
            context,
            icon: Icons.person_outline,
            title: 'Profile',
            subtitle: 'Account Settings',
            route: '/profile',
          ),
        ],
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
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF007AFF)),
      title: Text(title, style: GoogleFonts.poppins()),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
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
