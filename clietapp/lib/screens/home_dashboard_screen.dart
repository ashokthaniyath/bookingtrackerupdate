import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../widgets/invoice_card.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // UI Enhancement: Initialize Fade Animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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

  void _showFeature(BuildContext context, String label, String route) {
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeOfDay = now.hour < 12
        ? 'Morning'
        : now.hour < 17
        ? 'Afternoon'
        : 'Evening';

    final features = [
      _FeatureCard(
        icon: Icons.calendar_month_rounded,
        title: 'Calendar',
        description:
            "Visualize bookings\n• Add bookings by date\n• See room availability",
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => _showFeature(context, 'Calendar', '/calendar'),
      ),
      _FeatureCard(
        icon: Icons.bed_rounded,
        title: 'Rooms',
        description:
            "Manage room types & pricing\n• Add/edit types\n• Adjust rates",
        gradient: const LinearGradient(
          colors: [Color(0xFF14B8A6), Color(0xFF06B6D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => _showFeature(context, 'Rooms', '/rooms'),
      ),
      _FeatureCard(
        icon: Icons.people_alt_rounded,
        title: 'Guest List',
        description:
            "Manage guest details\n• View all customers\n• Link to booking history",
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => _showFeature(context, 'Guest List', '/guests'),
      ),
      _FeatureCard(
        icon: Icons.attach_money_rounded,
        title: 'Sales / Payment',
        description:
            "Income & pending payments\n• Charts for earnings\n• Room performance",
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => _showFeature(context, 'Sales / Payment', '/sales'),
      ),
      _FeatureCard(
        icon: Icons.analytics_outlined,
        title: 'Analytics',
        description:
            "Visualize trends and performance\n• Bookings, occupancy, revenue\n• Interactive charts",
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => _showFeature(context, 'Analytics', '/analytics'),
      ),
    ];

    // UI Enhancement: Luxury Gradient Background
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
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                // UI Enhancement: Luxury Welcome Header
                SliverToBoxAdapter(
                  child: AnimationConfiguration.staggeredList(
                    position: 0,
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: Container(
                          margin: const EdgeInsets.all(20),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                offset: const Offset(0, 8),
                                blurRadius: 24,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.villa,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Good $timeOfDay!',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            color: Colors.white.withValues(
                                              alpha: 0.9,
                                            ),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          'Lakshadweep Resort',
                                          style: GoogleFonts.poppins(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Last updated: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} IST',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                        fontWeight: FontWeight.w500,
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
                  ),
                ),

                // UI Enhancement: Luxury Invoice Card
                SliverToBoxAdapter(
                  child: AnimationConfiguration.staggeredList(
                    position: 1,
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: InvoiceCard(),
                        ),
                      ),
                    ),
                  ),
                ),

                // UI Enhancement: Quick Actions Header
                SliverToBoxAdapter(
                  child: AnimationConfiguration.staggeredList(
                    position: 2,
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF14B8A6),
                                      Color(0xFF06B6D4),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.flash_on,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Quick Actions',
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // UI Enhancement: Luxury Features Grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: AnimationLimiter(
                    child: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 1.0,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        if (index >= features.length) return null;
                        return AnimationConfiguration.staggeredGrid(
                          position: index,
                          duration: const Duration(milliseconds: 600),
                          columnCount: 2,
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(child: features[index]),
                          ),
                        );
                      }, childCount: features.length),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 100), // Space for bottom navigation
                ),
              ],
            ),
          ),
        ),
        // UI Enhancement: Luxury Floating Action Button
        floatingActionButton: AnimationConfiguration.staggeredList(
          position: 6,
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.4),
                      offset: const Offset(0, 8),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/booking-form');
                  },
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  tooltip: 'New Booking',
                  child: const Icon(Icons.add, size: 32, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}

// UI Enhancement: Luxury Feature Card with Gradient
class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final LinearGradient gradient;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    required this.gradient,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _hoverController.forward(),
      onTapUp: (_) => _hoverController.reverse(),
      onTapCancel: () => _hoverController.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: widget.gradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradient.colors.first.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // UI Enhancement: Icon with backdrop
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(widget.icon, size: 28, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    // UI Enhancement: Title with Poppins font
                    Text(
                      widget.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // UI Enhancement: Description with better styling
                    Text(
                      widget.description,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
