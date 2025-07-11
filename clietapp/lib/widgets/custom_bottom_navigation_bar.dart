import 'package:flutter/material.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 80,
        width: MediaQuery.of(context).size.width - 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Fix: Reconfigured Bottom Navigation Bar - Core 4 pages only
            _buildNavItem(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              index: 0,
              label: 'Home',
            ),
            _buildNavItem(
              icon: Icons.calendar_month_outlined,
              selectedIcon: Icons.calendar_month,
              index: 1,
              label: 'Calendar',
            ),
            _buildNavItem(
              icon: Icons.receipt_long_outlined,
              selectedIcon: Icons.receipt_long,
              index: 2,
              label: 'Invoices',
            ),
            _buildNavItem(
              icon: Icons.book_online_outlined,
              selectedIcon: Icons.book_online,
              index: 3,
              label: 'Booking',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    IconData? selectedIcon,
    required int index,
    required String label,
  }) {
    final bool isSelected = selectedIndex == index;
    final IconData displayIcon = isSelected && selectedIcon != null
        ? selectedIcon
        : icon;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          // Direct navigation call
          onItemTapped(index);
        },
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.transparent,
                ),
                child: Icon(
                  displayIcon,
                  size: 22,
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
