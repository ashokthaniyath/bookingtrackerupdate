import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/resort_data_provider.dart';
import '../models/booking.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Bug Prevention: PostFrameCallback for safe animation start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fadeController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: _buildDrawer(),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Consumer<ResortDataProvider>(
            builder: (context, provider, child) {
              final bookings = provider.bookings;
              final paidBookings = bookings
                  .where((b) => b.paymentStatus.toLowerCase() == 'paid')
                  .toList();
              final unpaidBookings = bookings
                  .where((b) => b.paymentStatus.toLowerCase() != 'paid')
                  .toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Cards Row 1 - Revenue & Status
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'Total Revenue',
                            value: '₹${_calculateTotalRevenue(paidBookings)}',
                            icon: Icons.attach_money,
                            color: const Color(0xFF14B8A6),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'Pending',
                            value: '${unpaidBookings.length}',
                            icon: Icons.pending_actions,
                            color: const Color(0xFFF43F5E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Summary Cards Row 2 - AI Analytics
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'AI Bookings',
                            value: '${_getAIBookingsCount(bookings)}',
                            icon: Icons.smart_toy,
                            color: const Color(0xFF667EEA),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'AI Revenue',
                            value: '₹${_calculateAIRevenue(bookings)}',
                            icon: Icons.auto_awesome,
                            color: const Color(0xFF764BA2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Paid Invoices Section
                    _buildSectionHeader('Paid Invoices'),
                    const SizedBox(height: 16),
                    if (paidBookings.isNotEmpty) ...[
                      ...paidBookings.map(
                        (booking) => _buildInvoiceCard(booking, isPaid: true),
                      ),
                    ] else ...[
                      _buildEmptyStateCard(
                        'No paid invoices yet',
                        Icons.receipt_long,
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Pending Invoices Section
                    _buildSectionHeader('Pending Invoices'),
                    const SizedBox(height: 16),
                    if (unpaidBookings.isNotEmpty) ...[
                      ...unpaidBookings.map(
                        (booking) => _buildInvoiceCard(booking, isPaid: false),
                      ),
                    ] else ...[
                      _buildEmptyStateCard(
                        'No pending invoices',
                        Icons.check_circle_outline,
                      ),
                    ],

                    const SizedBox(height: 24),

                    if (bookings.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(40),
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
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Invoices Found',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Invoices will appear here when bookings are created',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
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
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF14B8A6),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceCard(Booking booking, {required bool isPaid}) {
    final isAIBooking = booking.notes.contains('Created by AI Assistant');

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPaid
                  ? const Color(0xFF14B8A6).withValues(alpha: 0.2)
                  : const Color(0xFFF43F5E).withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, 5),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isAIBooking) ...[
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF667EEA),
                                      Color(0xFF764BA2),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.smart_toy,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                'Invoice #${(booking.id ?? booking.hashCode.toString()).padLeft(8, '0').toUpperCase()}',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (isAIBooking) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF667EEA),
                                      Color(0xFF764BA2),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'AI Created',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                booking.guest.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isPaid
                          ? const Color(0xFF14B8A6)
                          : const Color(0xFFF43F5E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isPaid ? 'PAID' : 'PENDING',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Check-in',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '${booking.checkIn.day}/${booking.checkIn.month}/${booking.checkIn.year}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Check-out',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '${booking.checkOut.day}/${booking.checkOut.month}/${booking.checkOut.year}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Room',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          booking.room.number.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    '₹${_calculateBookingAmount(booking)}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF14B8A6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // AI Badge positioned at top-right for additional emphasis
        if (isAIBooking)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withValues(alpha: 0.3),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.smart_toy, size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    'AI',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyStateCard(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  String _calculateTotalRevenue(List<Booking> paidBookings) {
    double total = 0;
    for (var booking in paidBookings) {
      total += _calculateBookingAmountDouble(booking);
    }
    return total.toStringAsFixed(2);
  }

  String _calculateBookingAmount(Booking booking) {
    final nights = booking.checkOut.difference(booking.checkIn).inDays;
    double baseRate;

    switch (booking.room.type.toLowerCase()) {
      case 'suite':
        baseRate = 7000.0; // ₹7000 per night
        break;
      case 'deluxe':
        baseRate = 6000.0; // ₹6000 per night
        break;
      case 'standard':
      default:
        baseRate = 5000.0; // ₹5000 per night
        break;
    }

    final total = nights * baseRate;
    return total.toStringAsFixed(2);
  }

  double _calculateBookingAmountDouble(Booking booking) {
    final nights = booking.checkOut.difference(booking.checkIn).inDays;
    double baseRate;

    switch (booking.room.type.toLowerCase()) {
      case 'suite':
        baseRate = 7000.0; // ₹7000 per night
        break;
      case 'deluxe':
        baseRate = 6000.0; // ₹6000 per night
        break;
      case 'standard':
      default:
        baseRate = 5000.0; // ₹5000 per night
        break;
    }

    return nights * baseRate;
  }

  // AI Analytics Methods
  int _getAIBookingsCount(List<Booking> bookings) {
    return bookings
        .where((booking) => booking.notes.contains('Created by AI Assistant'))
        .length;
  }

  String _calculateAIRevenue(List<Booking> bookings) {
    final aiBookings = bookings
        .where(
          (booking) =>
              booking.notes.contains('Created by AI Assistant') &&
              booking.depositPaid,
        )
        .toList();

    double total = 0;
    for (var booking in aiBookings) {
      total += _calculateBookingAmountDouble(booking);
    }
    return total.toStringAsFixed(2);
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
          _buildDrawerItem(Icons.person_outline, 'Profile', '/profile'),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, String route) {
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
}
