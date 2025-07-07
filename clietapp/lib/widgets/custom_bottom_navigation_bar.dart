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
            _buildNavItem(
              icon: Icons.dashboard_outlined,
              selectedIcon: Icons.dashboard,
              index: 0,
              label: 'Dashboard',
            ),
            _buildNavItem(
              icon: Icons.bed_outlined,
              selectedIcon: Icons.bed,
              index: 1,
              label: 'Rooms',
            ),
            _buildNavItem(
              icon: Icons.people_outline,
              selectedIcon: Icons.people,
              index: 2,
              label: 'Guests',
            ),
            _buildNavItem(
              icon: Icons.receipt_long_outlined,
              selectedIcon: Icons.receipt_long,
              index: 3,
              label: 'Invoices',
            ),
            _buildNavItem(
              icon: Icons.analytics_outlined,
              selectedIcon: Icons.analytics,
              index: 4,
              label: 'Analytics',
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
          onItemTapped(index);
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
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
