import 'package:flutter/material.dart';
import 'package:ailin_tattileri_app/core/theme/app_colors.dart';
import 'package:ailin_tattileri_app/features/admin/dashboard/admin_dashboard_screen.dart';
import 'package:ailin_tattileri_app/features/admin/orders/admin_orders_screen.dart';
import 'package:ailin_tattileri_app/features/admin/workers/workers_screen.dart';
import 'package:ailin_tattileri_app/features/admin/partners/partners_screen.dart';
import 'package:ailin_tattileri_app/features/client/profile/profile_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AdminDashboardScreen(), // 0. Home
    const WorkersScreen(), // 1. Workers
    const PartnersScreen(), // 2. Venues/Partners
    const AdminOrdersScreen(), // 3. Orders
    const ProfileScreen(), // 4. Profile
  ];

  @override
  Widget build(BuildContext context) {
    // Localize labels if possible, or use hardcoded Russian to match screenshot
    // Using hardcoded Russian based on user's screenshots
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15), // Deeper shadow
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: isDark ? Colors.grey[500] : Colors.grey[400],
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12, // Keep labels slightly smaller to fit standard UI
              height: 1.5,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
              height: 1.5,
            ),
            items: [
              _buildNavItem(
                icon: Icons.home_rounded,
                label: "Главная",
                isSelected: _currentIndex == 0,
              ),
              _buildNavItem(
                icon: Icons.people_alt_rounded,
                label: "Работники",
                isSelected: _currentIndex == 1,
              ),
              _buildNavItem(
                icon: Icons.store_mall_directory_rounded,
                label: "Заведения",
                isSelected: _currentIndex == 2,
              ),
              _buildNavItem(
                icon: Icons.receipt_long_rounded,
                label: "Заказы",
                isSelected: _currentIndex == 3,
              ),
              _buildNavItem(
                icon: Icons.person_rounded,
                label: "Профиль",
                isSelected: _currentIndex == 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return BottomNavigationBarItem(
      icon: Icon(icon, size: 28), // Standard size unselected
      activeIcon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, size: 30, color: AppColors.primary),
      ),
      label: label,
    );
  }
}
