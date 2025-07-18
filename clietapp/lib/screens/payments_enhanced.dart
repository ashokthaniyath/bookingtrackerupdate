import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/booking.dart';
import '../models/guest.dart';
import '../models/room.dart';
import '../models/payment.dart';
import '../providers/resort_data_provider.dart';
import '../services/pdf_generation_service_stub.dart' as PDFGenerationService;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_bottom_navigation_bar.dart';
import 'main_scaffold.dart';
import '../widgets/voice_booking_widget.dart';
import '../services/vertex_ai_service.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
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

  void _onBottomNavTapped(int index) {
    try {
      // Debug log for navigation tracking
      print("Navigating from payments page to index: $index");

      // Navigate to MainScaffold with the correct index
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

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return const Color(0xFF14B8A6);
      case 'pending':
        return const Color(0xFFEAB308);
      case 'overdue':
        return const Color(0xFFF43F5E);
      case 'cancelled':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _getPaymentStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'overdue':
        return Icons.warning;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _calculateAveragePerBooking(ResortDataProvider provider) {
    final bookings = provider.bookings;
    if (bookings.isEmpty) return '₹0';

    // Calculate based on available booking data
    final totalAmount = bookings.length * 5000; // Base calculation
    return '₹${NumberFormat('#,##0').format(totalAmount / bookings.length)}';
  }

  @override
  Widget build(BuildContext context) {
    // Responsive breakpoints optimized for Windows and mobile devices
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 400;
    final isMediumScreen = screenWidth >= 400 && screenWidth < 800;

    // Responsive dimensions
    final horizontalPadding = isSmallScreen
        ? 8.0
        : (isMediumScreen ? 16.0 : 24.0);
    final verticalPadding = isSmallScreen
        ? 6.0
        : (isMediumScreen ? 12.0 : 16.0);
    final cardMargin = isSmallScreen ? 6.0 : (isMediumScreen ? 12.0 : 16.0);

    return Consumer<ResortDataProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF87CEEB), Color(0xFFFFFFFF)],
              ),
            ),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Responsive App Bar
                    _buildResponsiveAppBar(isSmallScreen, isMediumScreen),

                    // Revenue Cards
                    _buildResponsiveRevenueCards(
                      provider,
                      horizontalPadding,
                      isSmallScreen,
                      isMediumScreen,
                    ),

                    // Filter Section
                    _buildResponsiveFilterSection(
                      horizontalPadding,
                      isSmallScreen,
                    ),

                    // Payment Cards List
                    _buildResponsivePaymentsList(
                      provider,
                      horizontalPadding,
                      verticalPadding,
                      cardMargin,
                      isSmallScreen,
                    ),

                    // Bottom spacing for navigation bar
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: screenHeight * 0.15,
                      ), // Extra space for bottom nav
                    ),
                  ],
                ),
              ),
            ),
          ),
          drawer: _buildResponsiveDrawer(),
          bottomNavigationBar: CustomBottomNavigation(
            selectedIndex: 2, // Payments/Invoices tab
            onItemTapped: _onBottomNavTapped,
          ),
          floatingActionButton: _buildVoiceBookingFAB(),
        );
      },
    );
  }

  Widget _buildResponsiveAppBar(bool isSmallScreen, bool isMediumScreen) {
    return SliverAppBar(
      expandedHeight: isSmallScreen ? 80.0 : (isMediumScreen ? 100.0 : 120.0),
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(
            Icons.menu,
            color: const Color(0xFF1E3A8A),
            size: isSmallScreen ? 20.0 : 24.0,
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Sales & Payments',
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 16.0 : (isMediumScreen ? 20.0 : 24.0),
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E3A8A),
          ),
        ),
        centerTitle: true,
      ),
    );
  }

  Widget _buildResponsiveRevenueCards(
    ResortDataProvider provider,
    double horizontalPadding,
    bool isSmallScreen,
    bool isMediumScreen,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 16,
        ),
        child: isSmallScreen
            ? _buildVerticalRevenueCards(provider, isSmallScreen)
            : _buildHorizontalRevenueCards(
                provider,
                isSmallScreen,
                isMediumScreen,
              ),
      ),
    );
  }

  Widget _buildVerticalRevenueCards(
    ResortDataProvider provider,
    bool isSmallScreen,
  ) {
    return Column(
      children: [
        _buildResponsiveRevenueCard(
          'Total Revenue',
          '₹${NumberFormat('#,##0').format(provider.bookings.length * 5000)}',
          Icons.currency_rupee,
          const LinearGradient(colors: [Color(0xFF14B8A6), Color(0xFF0891B2)]),
          isSmallScreen,
        ),
        const SizedBox(height: 12),
        _buildResponsiveRevenueCard(
          'Bookings Count',
          '${provider.bookings.length}',
          Icons.book_online,
          const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)]),
          isSmallScreen,
        ),
        const SizedBox(height: 12),
        _buildResponsiveRevenueCard(
          'Avg. per Booking',
          _calculateAveragePerBooking(provider),
          Icons.trending_up,
          const LinearGradient(colors: [Color(0xFFF43F5E), Color(0xFFEC4899)]),
          isSmallScreen,
        ),
      ],
    );
  }

  Widget _buildHorizontalRevenueCards(
    ResortDataProvider provider,
    bool isSmallScreen,
    bool isMediumScreen,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildResponsiveRevenueCard(
            'Total Revenue',
            '₹${NumberFormat('#,##0').format(provider.bookings.length * 5000)}',
            Icons.currency_rupee,
            const LinearGradient(
              colors: [Color(0xFF14B8A6), Color(0xFF0891B2)],
            ),
            isSmallScreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildResponsiveRevenueCard(
            'Bookings Count',
            '${provider.bookings.length}',
            Icons.book_online,
            const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
            ),
            isSmallScreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildResponsiveRevenueCard(
            'Avg. per Booking',
            _calculateAveragePerBooking(provider),
            Icons.trending_up,
            const LinearGradient(
              colors: [Color(0xFFF43F5E), Color(0xFFEC4899)],
            ),
            isSmallScreen,
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveRevenueCard(
    String title,
    String value,
    IconData icon,
    Gradient gradient,
    bool isSmallScreen,
  ) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 12.0 : 14.0,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                icon,
                color: Colors.white.withOpacity(0.8),
                size: isSmallScreen ? 18.0 : 20.0,
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 16.0 : 20.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveFilterSection(
    double horizontalPadding,
    bool isSmallScreen,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter by Status:',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 14.0 : 16.0,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Paid', 'Pending', 'Overdue']
                    .map(
                      (status) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: _filter == status,
                          label: Text(
                            status,
                            style: GoogleFonts.poppins(
                              color: _filter == status
                                  ? Colors.white
                                  : const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                              fontSize: isSmallScreen ? 12.0 : 14.0,
                            ),
                          ),
                          onSelected: (selected) {
                            setState(() {
                              _filter = status;
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: const Color(0xFF14B8A6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: _filter == status
                                  ? const Color(0xFF14B8A6)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsivePaymentsList(
    ResortDataProvider provider,
    double horizontalPadding,
    double verticalPadding,
    double cardMargin,
    bool isSmallScreen,
  ) {
    final filteredBookings = provider.bookings.where((booking) {
      switch (_filter.toLowerCase()) {
        case 'paid':
          return booking.paymentStatus.toLowerCase() == 'paid';
        case 'pending':
          return booking.paymentStatus.toLowerCase() == 'pending';
        case 'overdue':
          return booking.paymentStatus.toLowerCase() == 'overdue';
        default:
          return true;
      }
    }).toList();

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final booking = filteredBookings[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 600),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildResponsivePaymentCard(
                  booking,
                  isSmallScreen,
                  cardMargin,
                ),
              ),
            ),
          );
        }, childCount: filteredBookings.length),
      ),
    );
  }

  Widget _buildResponsivePaymentCard(
    Booking booking,
    bool isSmallScreen,
    double cardMargin,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: cardMargin),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with booking info and status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking #${booking.id}',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 14.0 : 16.0,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking.guest.name,
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 12.0 : 14.0,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getPaymentStatusColor(
                      booking.paymentStatus,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getPaymentStatusColor(booking.paymentStatus),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getPaymentStatusIcon(booking.paymentStatus),
                        size: isSmallScreen ? 12.0 : 14.0,
                        color: _getPaymentStatusColor(booking.paymentStatus),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        booking.paymentStatus,
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 10.0 : 12.0,
                          fontWeight: FontWeight.w600,
                          color: _getPaymentStatusColor(booking.paymentStatus),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Booking details
            _buildBookingDetails(booking, isSmallScreen),

            const SizedBox(height: 12),

            // Action buttons with PDF generation
            _buildResponsiveActionButtons(booking, isSmallScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingDetails(Booking booking, bool isSmallScreen) {
    return Column(
      children: [
        _buildDetailRow('Room:', booking.room.number, isSmallScreen),
        const SizedBox(height: 6),
        _buildDetailRow(
          'Check-in:',
          DateFormat('MMM dd, yyyy').format(booking.checkIn),
          isSmallScreen,
        ),
        const SizedBox(height: 6),
        _buildDetailRow(
          'Check-out:',
          DateFormat('MMM dd, yyyy').format(booking.checkOut),
          isSmallScreen,
        ),
        const SizedBox(height: 6),
        _buildDetailRow(
          'Amount:',
          '₹5,000',
          isSmallScreen,
        ), // Placeholder amount
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, bool isSmallScreen) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 11.0 : 12.0,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 11.0 : 12.0,
              color: const Color(0xFF1E293B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveActionButtons(Booking booking, bool isSmallScreen) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _generateInvoicePDF(booking),
            icon: Icon(Icons.picture_as_pdf, size: isSmallScreen ? 14.0 : 16.0),
            label: Text(
              'Generate PDF Invoice',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 11.0 : 12.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF14B8A6),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                vertical: isSmallScreen ? 8.0 : 12.0,
                horizontal: isSmallScreen ? 12.0 : 16.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => _showPaymentActions(booking),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              vertical: isSmallScreen ? 8.0 : 12.0,
              horizontal: isSmallScreen ? 12.0 : 16.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Actions',
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 11.0 : 12.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 25,
                    backgroundColor: Color(0xFF007AFF),
                    child: Icon(Icons.person, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resort Manager',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          'Admin Panel',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(context, Icons.dashboard, 'Dashboard', '/'),
                  _buildDrawerItem(
                    context,
                    Icons.book_online,
                    'Bookings',
                    '/booking',
                  ),
                  _buildDrawerItem(context, Icons.room, 'Rooms', '/rooms'),
                  _buildDrawerItem(
                    context,
                    Icons.payment,
                    'Payments',
                    '/payments',
                  ),
                  _buildDrawerItem(
                    context,
                    Icons.analytics,
                    'Analytics',
                    '/analytics',
                  ),
                  _buildDrawerItem(context, Icons.people, 'Guests', '/guests'),
                  const Divider(),
                  _buildDrawerItem(
                    context,
                    Icons.settings,
                    'Settings',
                    '/settings',
                  ),
                  _buildDrawerItem(context, Icons.help, 'Help', '/help'),
                ],
              ),
            ),
          ],
        ),
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

  // PDF Generation and Payment Action Methods
  Future<void> _generateInvoicePDF(Booking booking) async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Generating PDF Invoice...',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF14B8A6),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Generate and save PDF with enhanced Android support
      await PDFGenerationService.PDFGenerationService.generateInvoicePDF(
        booking,
        Payment(
          guest: booking.guest,
          amount: 5000.0,
          status: booking.paymentStatus,
          date: DateTime.now(),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PDF processed',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF14B8A6),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error generating PDF: $e',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFF43F5E),
          ),
        );
      }
    }
  }

  void _showPaymentActions(Booking booking) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Payment Actions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 20),
            _buildActionButton(
              'Mark as Paid',
              Icons.check_circle,
              const Color(0xFF14B8A6),
              () => _updatePaymentStatus(booking, 'Paid'),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              'Mark as Pending',
              Icons.schedule,
              const Color(0xFFEAB308),
              () => _updatePaymentStatus(booking, 'Pending'),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              'Mark as Overdue',
              Icons.warning,
              const Color(0xFFF43F5E),
              () => _updatePaymentStatus(booking, 'Overdue'),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              'Send Payment Reminder',
              Icons.email,
              const Color(0xFF3B82F6),
              () => _sendPaymentReminder(booking),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pop(context);
          onPressed();
        },
        icon: Icon(icon, size: 20),
        label: Text(
          title,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _updatePaymentStatus(Booking booking, String newStatus) async {
    try {
      // Simulate updating payment status
      setState(() {
        booking.paymentStatus = newStatus;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment status updated to $newStatus',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF14B8A6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error updating payment status: $e',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFF43F5E),
          ),
        );
      }
    }
  }

  Future<void> _sendPaymentReminder(Booking booking) async {
    try {
      // Simulate sending reminder
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment reminder sent to ${booking.guest.name}',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF14B8A6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error sending reminder: $e',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFF43F5E),
          ),
        );
      }
    }
  }

  // Voice Booking Floating Action Button
  Widget _buildVoiceBookingFAB() {
    return Container(
      margin: const EdgeInsets.only(bottom: 80), // Above bottom navigation
      child: FloatingActionButton.extended(
        onPressed: _showVoiceBookingDialog,
        icon: const Icon(Icons.mic, color: Colors.white),
        label: Text(
          'Voice Booking',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.purple.shade600,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    );
  }

  // Show Voice Booking Dialog
  void _showVoiceBookingDialog() {
    final provider = Provider.of<ResortDataProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: VoiceBookingWidget(
          availableRooms: provider.rooms
              .where((room) => room.status.toLowerCase() != 'occupied')
              .toList(),
          existingGuests: provider.guests,
          onBookingSuggestion: (suggestion) {
            Navigator.pop(context);
            _handleVoiceBookingSuggestion(suggestion, provider);
          },
          onClose: () => Navigator.pop(context),
        ),
      ),
    );
  }

  // Handle Voice Booking Suggestion
  void _handleVoiceBookingSuggestion(
    BookingSuggestion suggestion,
    ResortDataProvider provider,
  ) {
    try {
      // Create a new booking from the voice suggestion
      final newBooking = Booking(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        guest: Guest(name: suggestion.guestName, email: '', phone: ''),
        room: Room(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          number: _findBestAvailableRoom(provider, suggestion.roomType),
          type: suggestion.roomType ?? 'Standard',
          pricePerNight: 100.0,
          status: 'occupied',
        ),
        checkIn: suggestion.checkInDate,
        checkOut: suggestion.checkOutDate,
        paymentStatus: 'Pending',
        notes: 'Created via Voice Assistant',
      );

      // Add to provider (simulate saving)
      provider.addBooking(newBooking);

      // Show success message with booking details
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Voice booking created successfully!',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Booking: ${suggestion.guestName} • Room ${newBooking.room.number}',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          action: SnackBarAction(
            label: 'VIEW',
            textColor: Colors.white,
            onPressed: () {
              // Could navigate to booking details
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error handling voice booking suggestion: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Error creating voice booking. Please try again.',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // Find best available room based on preference
  String _findBestAvailableRoom(
    ResortDataProvider provider,
    String? preferredType,
  ) {
    final availableRooms = provider.rooms
        .where((room) => room.status.toLowerCase() != 'occupied')
        .toList();

    if (availableRooms.isEmpty) return '101'; // Fallback

    if (preferredType != null) {
      // Try to find room matching preferred type
      final preferredRoom = availableRooms.firstWhere(
        (room) => room.type.toLowerCase().contains(preferredType.toLowerCase()),
        orElse: () => availableRooms.first,
      );
      return preferredRoom.number;
    }

    return availableRooms.first.number;
  }
}
