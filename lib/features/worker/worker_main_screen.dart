import 'package:flutter/material.dart';
import 'package:ailin_tattileri_app/core/theme/app_colors.dart';
import 'package:ailin_tattileri_app/features/worker/dashboard/worker_dashboard_screen.dart';
import 'package:ailin_tattileri_app/features/worker/salary/worker_salary_screen.dart';
import 'package:ailin_tattileri_app/features/worker/advance/worker_advance_screen.dart';
import 'package:ailin_tattileri_app/features/client/profile/profile_screen.dart';

class WorkerMainScreen extends StatefulWidget {
  const WorkerMainScreen({super.key});

  @override
  State<WorkerMainScreen> createState() => _WorkerMainScreenState();
}

class _WorkerMainScreenState extends State<WorkerMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const WorkerDashboardScreen(),
    const WorkerSalaryScreen(),
    const WorkerAdvanceScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
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
              fontSize: 12,
              height: 1.5,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
              height: 1.5,
            ),
            items: [
              _buildNavItem(
                icon: Icons.work_rounded,
                selectedIcon: Icons.work_rounded,
                label: "Смена",
                isSelected: _currentIndex == 0,
              ),
              _buildNavItem(
                icon: Icons.attach_money_rounded,
                selectedIcon: Icons.attach_money_rounded,
                label: "Зарплата",
                isSelected: _currentIndex == 1,
              ),
              _buildNavItem(
                icon: Icons.account_balance_wallet_outlined,
                selectedIcon: Icons.account_balance_wallet,
                label: "Аванс",
                isSelected: _currentIndex == 2,
              ),
              _buildNavItem(
                icon: Icons.person_rounded,
                selectedIcon: Icons.person,
                label: "Профиль",
                isSelected: _currentIndex == 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool isSelected,
  }) {
    return BottomNavigationBarItem(
      icon: Icon(icon, size: 28),
      activeIcon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(selectedIcon, size: 30, color: AppColors.primary),
      ),
      label: label,
    );
  }
}
