import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/guest.dart';
import '../models/booking.dart';
import '../providers/resort_data_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../widgets/custom_bottom_navigation_bar.dart';
import 'main_scaffold.dart';

class GuestManagementPage extends StatefulWidget {
  const GuestManagementPage({super.key});

  @override
  State<GuestManagementPage> createState() => _GuestManagementPageState();
}

class _GuestManagementPageState extends State<GuestManagementPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
    _searchController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    try {
      // Debug log for navigation tracking
      print("Navigating from guest management to index: $index");

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

  void _showGuestDialog({Guest? guest}) {
    final nameController = TextEditingController(text: guest?.name ?? '');
    final emailController = TextEditingController(text: guest?.email ?? '');
    final phoneController = TextEditingController(text: guest?.phone ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Text(
          guest == null ? 'Add Guest' : 'Edit Guest',
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
                controller: nameController,
                style: GoogleFonts.poppins(),
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: GoogleFonts.poppins(
                    color: const Color(0xFF64748B),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  prefixIcon: const Icon(
                    Icons.person,
                    color: Color(0xFF64748B),
                  ),
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
                controller: emailController,
                style: GoogleFonts.poppins(),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: GoogleFonts.poppins(
                    color: const Color(0xFF64748B),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  prefixIcon: const Icon(Icons.email, color: Color(0xFF64748B)),
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
                controller: phoneController,
                style: GoogleFonts.poppins(),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: GoogleFonts.poppins(
                    color: const Color(0xFF64748B),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  prefixIcon: const Icon(Icons.phone, color: Color(0xFF64748B)),
                ),
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
                colors: [Color(0xFF14B8A6), Color(0xFF06B6D4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF14B8A6).withValues(alpha: 0.3),
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
                // Sync: Use ResortDataProvider for data management
                final provider = Provider.of<ResortDataProvider>(
                  context,
                  listen: false,
                );

                if (guest == null) {
                  // Add new guest
                  final newGuest = Guest(
                    name: nameController.text,
                    email: emailController.text,
                    phone: phoneController.text,
                  );
                  await provider.addGuest(newGuest);
                } else {
                  // Update existing guest
                  final guestIndex = provider.guests.indexWhere(
                    (g) => g.email == guest.email,
                  );
                  if (guestIndex != -1) {
                    final updatedGuest = Guest(
                      id: guest.id, // Preserve the ID
                      name: nameController.text,
                      email: emailController.text,
                      phone: phoneController.text,
                    );
                    // Use the guest's ID if available, otherwise use a placeholder
                    final guestId = guest.id ?? guestIndex.toString();
                    await provider.updateGuest(guestId, updatedGuest);
                  }
                }
                if (mounted) Navigator.pop(context);
                // Note: setState removed as provider handles state updates
              },
              child: Text(
                guest == null ? 'Add Guest' : 'Update Guest',
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

  void _deleteGuest(Guest guest) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Delete Guest',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xFFF43F5E),
          ),
        ),
        content: Text(
          'Are you sure you want to delete ${guest.name}? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () async {
              // Sync: Use ResortDataProvider for data management
              final provider = Provider.of<ResortDataProvider>(
                context,
                listen: false,
              );
              final guestIndex = provider.guests.indexWhere(
                (g) => g.email == guest.email,
              );
              if (guestIndex != -1) {
                final guestToDelete = provider.guests[guestIndex];
                final guestId = guestToDelete.id ?? guestIndex.toString();
                await provider.deleteGuest(guestId);
              }
              if (mounted) Navigator.pop(context);
              // Note: setState removed as provider handles state updates
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
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
      leading: Icon(icon, color: const Color(0xFF007AFF)),
      title: Text(title, style: GoogleFonts.poppins()),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
    );
  }

  List<Guest> _getFilteredGuests(List<Guest> guests) {
    if (_searchQuery.isEmpty) return guests;

    return guests.where((guest) {
      return guest.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (guest.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false) ||
          (guest.phone?.contains(_searchQuery) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Data Flow: Use Consumer to listen to provider changes
    return Consumer<ResortDataProvider>(
      builder: (context, provider, child) {
        final filteredGuests = _getFilteredGuests(provider.guests);

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
                child: CustomScrollView(
                  slivers: [
                    // UI Enhancement: Modern App Bar with Search
                    SliverAppBar(
                      expandedHeight: 200,
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
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(
                          'Guest List',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E3A8A),
                          ),
                        ),
                        centerTitle: true,
                        background: Padding(
                          padding: const EdgeInsets.only(
                            left: 20,
                            right: 20,
                            bottom: 60,
                            top: 80,
                          ),
                          child: Column(
                            children: [
                              const Spacer(),
                              // UI Enhancement: Glassmorphism Search Bar
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF1E3A8A),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Search guests...',
                                    hintStyle: GoogleFonts.poppins(
                                      color: const Color(
                                        0xFF1E3A8A,
                                      ).withValues(alpha: 0.7),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      color: Color(0xFF1E3A8A),
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _searchQuery = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      actions: [
                        // UI Enhancement: Floating Add Button
                        Container(
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF14B8A6), Color(0xFF06B6D4)],
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
                            onPressed: () => _showGuestDialog(),
                            icon: const Icon(
                              Icons.person_add,
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
                                'Total Guests',
                                provider.guests.length.toString(),
                                Icons.people,
                                const Color(0xFF1E3A8A),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatsCard(
                                'Active Bookings',
                                provider.activeBookings.length.toString(),
                                Icons.hotel,
                                const Color(0xFF14B8A6),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatsCard(
                                'Check-ins Today',
                                provider.todayCheckIns.length.toString(),
                                Icons.login,
                                const Color(0xFFEAB308),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // UI Enhancement: Guest List with Animations - Sync: Provider data
                    filteredGuests.isEmpty
                        ? SliverToBoxAdapter(
                            child: Center(
                              child: Column(
                                children: [
                                  const SizedBox(height: 60),
                                  Icon(
                                    _searchQuery.isEmpty
                                        ? Icons.people_outline
                                        : Icons.search_off,
                                    size: 80,
                                    color: const Color(0xFF64748B),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    _searchQuery.isEmpty
                                        ? 'No guests yet\nAdd your first guest!'
                                        : 'No guests found\nTry a different search term',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            sliver: AnimationLimiter(
                              child: SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final guest = filteredGuests[index];
                                  return AnimationConfiguration.staggeredList(
                                    position: index,
                                    duration: const Duration(milliseconds: 500),
                                    child: SlideAnimation(
                                      horizontalOffset: 50.0,
                                      child: FadeInAnimation(
                                        child: _buildGuestCard(
                                          guest,
                                          provider.bookings,
                                        ),
                                      ),
                                    ),
                                  );
                                }, childCount: filteredGuests.length),
                              ),
                            ),
                          ),

                    const SliverToBoxAdapter(
                      child: SizedBox(
                        height: 100,
                      ), // Space for bottom navigation
                    ),
                  ],
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
                  Icons.person_outline,
                  'Profile',
                  '/profile',
                ),
              ],
            ),
          ),
          bottomNavigationBar: CustomBottomNavigation(
            selectedIndex: 1, // Guests are typically index 1, adjust as needed
            onItemTapped: _onTabSelected,
          ),
        );
      },
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

  // UI Enhancement: Elegant Guest Card Design
  Widget _buildGuestCard(Guest guest, List<Booking> bookings) {
    // Get guest's bookings - Sync: Using provider data
    final guestBookings = bookings
        .where((b) => b.guest.name == guest.name)
        .toList();

    final activeBookings = guestBookings
        .where(
          (b) =>
              DateTime.now().isAfter(b.checkIn) &&
              DateTime.now().isBefore(b.checkOut),
        )
        .toList();

    final upcomingBookings = guestBookings
        .where((b) => DateTime.now().isBefore(b.checkIn))
        .toList();

    // Check if any bookings were created by AI
    final aiBookings = guestBookings
        .where((b) => b.notes.contains('Created by AI Assistant'))
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          onTap: () => _showGuestDialog(guest: guest),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Guest Avatar with AI indicator
                    Stack(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              guest.name.isNotEmpty
                                  ? guest.name[0].toUpperCase()
                                  : 'G',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        // AI indicator badge
                        if (aiBookings.isNotEmpty)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF667EEA),
                                    Color(0xFF764BA2),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.smart_toy,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(width: 16),

                    // Guest Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  guest.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              // AI booking indicator
                              if (aiBookings.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF667EEA),
                                        Color(0xFF764BA2),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.smart_toy,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'AI',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            guest.email ?? 'No email',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            guest.phone ?? 'No phone',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Actions Menu
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        color: Color(0xFF64748B),
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showGuestDialog(guest: guest);
                        } else if (value == 'delete') {
                          _deleteGuest(guest);
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

                // Booking Status with AI indicators
                if (activeBookings.isNotEmpty ||
                    upcomingBookings.isNotEmpty ||
                    aiBookings.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (activeBookings.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF14B8A6,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.hotel,
                                size: 16,
                                color: Color(0xFF14B8A6),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Currently staying in Room ${activeBookings.first.room.number}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF14B8A6),
                                ),
                              ),
                              // Show AI icon if this is an AI booking
                              if (activeBookings.first.notes.contains(
                                'Created by AI Assistant',
                              )) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.smart_toy,
                                  size: 12,
                                  color: Color(0xFF14B8A6),
                                ),
                              ],
                            ],
                          ),
                        ),
                      if (upcomingBookings.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFEAB308,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.schedule,
                                size: 16,
                                color: Color(0xFFEAB308),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${upcomingBookings.length} upcoming booking(s)',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFEAB308),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // AI Bookings summary
                      if (aiBookings.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.smart_toy,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${aiBookings.length} AI booking${aiBookings.length != 1 ? 's' : ''}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
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
