import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/invoice_card.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  void _showFeature(BuildContext context, String label, String route) {
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final features = [
      _FeatureCard(
        icon: Icons.calendar_month_rounded,
        title: 'Calendar',
        description:
            "Visualize bookings\n• Add bookings by date\n• See room availability",
        onTap: () => _showFeature(context, 'Calendar', '/calendar'),
      ),
      _FeatureCard(
        icon: Icons.bed_rounded,
        title: 'Rooms',
        description:
            "Manage room types & pricing\n• Add/edit types\n• Adjust rates",
        onTap: () => _showFeature(context, 'Rooms', '/rooms'),
      ),
      _FeatureCard(
        icon: Icons.people_alt_rounded,
        title: 'Guest List',
        description:
            "Manage guest details\n• View all customers\n• Link to booking history",
        onTap: () => _showFeature(context, 'Guest List', '/guests'),
      ),
      _FeatureCard(
        icon: Icons.attach_money_rounded,
        title: 'Sales / Payment',
        description:
            "Income & pending payments\n• Charts for earnings\n• Room performance",
        onTap: () => _showFeature(context, 'Sales / Payment', '/sales'),
      ),
      _FeatureCard(
        icon: Icons.analytics_outlined,
        title: 'Analytics',
        description:
            "Visualize trends and performance\n• Bookings, occupancy, revenue\n• Interactive charts",
        onTap: () => _showFeature(context, 'Analytics', '/analytics'),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'NotionBook Home',
          style: GoogleFonts.inter(
            color: const Color(0xFF222B45),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Invoice Card
            const SizedBox(height: 10),
            const InvoiceCard(),

            // Features Grid
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF222B45),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 1.1,
                    children: features,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/booking-form');
        },
        backgroundColor: const Color(0xFF007AFF),
        tooltip: 'New Booking',
        child: const Icon(Icons.add, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: const Color(0xFF007AFF)),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF222B45),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}
