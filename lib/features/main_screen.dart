import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ailin_tattileri_app/core/theme/app_colors.dart';
import 'package:ailin_tattileri_app/core/services/auth_service.dart';
import 'package:ailin_tattileri_app/features/client/home/home_screen.dart';
import 'package:ailin_tattileri_app/features/client/profile/profile_screen.dart';
import 'package:ailin_tattileri_app/features/client/orders/client_orders_screen.dart';
import 'package:ailin_tattileri_app/features/admin/dashboard/admin_dashboard_screen.dart';
import 'package:ailin_tattileri_app/features/admin/workers/workers_screen.dart';
import 'package:ailin_tattileri_app/features/admin/partners/partners_screen.dart';
import 'package:ailin_tattileri_app/features/admin/orders/admin_orders_screen.dart';
import 'package:ailin_tattileri_app/features/worker/dashboard/worker_dashboard_screen.dart';
import 'package:ailin_tattileri_app/features/worker/salary/worker_salary_screen.dart';
import 'package:ailin_tattileri_app/features/worker/advance/worker_advance_screen.dart';
import 'package:ailin_tattileri_app/features/partner/debt/partner_debt_screen.dart';
import 'package:ailin_tattileri_app/l10n/app_localizations.dart';

class MainScreen extends StatefulWidget {
  final int initialTab;
  const MainScreen({super.key, this.initialTab = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    // 1. Listen to User Auth State
    return StreamBuilder<User?>(
      stream: _authService.user,
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final user = userSnapshot.data;
        // 2. Identify User Type
        if (user == null) {
          // Guest User
          return _MainScreenContent(
            userRole: 'guest',
            initialTab: widget.initialTab,
          );
        } else {
          // Logged In User - Needs Role Loading
          return _RoleLoader(userId: user.uid, initialTab: widget.initialTab);
        }
      },
    );
  }
}

// Separate widget to handle Role Loading securely
class _RoleLoader extends StatefulWidget {
  final String userId;
  final int initialTab;

  const _RoleLoader({required this.userId, required this.initialTab});

  @override
  State<_RoleLoader> createState() => _RoleLoaderState();
}

class _RoleLoaderState extends State<_RoleLoader> {
  late Stream<String?> _roleStream;

  @override
  void initState() {
    super.initState();
    _roleStream = AuthService().getUserRoleStream(widget.userId);
  }

  @override
  void didUpdateWidget(covariant _RoleLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userId != oldWidget.userId) {
      _roleStream = AuthService().getUserRoleStream(widget.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: _roleStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // While waiting for the *stream* to connect, we can show a loader
          // OR show the client view skeleton to make it feel faster.
          // Given the user complains about "wrong role", let's show loader briefly
          // but if it takes too long, it might be annoying.
          // Firestore cache usually responds instantly.
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (snapshot.hasError) {
          debugPrint('Role Fetch Error: ${snapshot.error}'); // Debug print
          // Fallback to client on error to prevent crash
          return _MainScreenContent(
            userRole: 'client',
            initialTab: widget.initialTab,
          );
        }

        final role = snapshot.data ?? 'client';
        debugPrint(
          'FINAL ROLE LOADED: $role',
        ); // Debug print to see what fetches
        return _MainScreenContent(
          userRole: role,
          initialTab: widget.initialTab,
        );
      },
    );
  }
}

// The actual UI Content (Bottom Navigation, etc)
class _MainScreenContent extends StatefulWidget {
  final String userRole;
  final int initialTab;

  const _MainScreenContent({required this.userRole, required this.initialTab});

  @override
  State<_MainScreenContent> createState() => _MainScreenContentState();
}

class _MainScreenContentState extends State<_MainScreenContent> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  @override
  void didUpdateWidget(covariant _MainScreenContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab) {
      setState(() {
        _currentIndex = widget.initialTab;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    final role = widget.userRole;

    List<Widget> screens = [];
    List<_NavItem> navItems = [];

    // Define Configuration based on Role
    if (role == 'admin') {
      screens = [
        const AdminDashboardScreen(),
        const WorkersScreen(),
        const PartnersScreen(),
        const AdminOrdersScreen(),
        const ProfileScreen(),
      ];
      navItems = [
        _NavItem(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          label: text.menuMain,
        ),
        _NavItem(
          icon: Icons.people_outline,
          selectedIcon: Icons.people,
          label: text.menuWorkers,
        ),
        _NavItem(
          icon: Icons.business_outlined,
          selectedIcon: Icons.business,
          label: "Заведения",
        ),
        _NavItem(
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long,
          label: text.menuOrders,
        ),
        _NavItem(
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          label: text.menuProfile,
        ),
      ];
    } else if (role == 'worker') {
      screens = [
        const WorkerDashboardScreen(),
        const WorkerSalaryScreen(),
        const WorkerAdvanceScreen(),
        const ProfileScreen(),
      ];
      navItems = [
        _NavItem(
          icon: Icons.work_outline,
          selectedIcon: Icons.work,
          label: text.menuShift,
        ),
        _NavItem(
          icon: Icons.attach_money_outlined,
          selectedIcon: Icons.attach_money,
          label: text.menuSalary,
        ),
        _NavItem(
          icon: Icons.account_balance_wallet_outlined,
          selectedIcon: Icons.account_balance_wallet,
          label: text.menuAdvance,
        ),
        _NavItem(
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          label: text.menuProfile,
        ),
      ];
    } else if (role == 'partner') {
      screens = [
        const HomeScreen(),
        const PartnerDebtScreen(),
        const ClientOrdersScreen(),
        const ProfileScreen(),
      ];
      navItems = [
        _NavItem(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          label: text.menuMain,
        ),
        _NavItem(
          icon: Icons.account_balance_wallet_outlined,
          selectedIcon: Icons.account_balance_wallet,
          label: Localizations.localeOf(context).languageCode == 'kk'
              ? "Қарыз"
              : "Долг",
        ),
        _NavItem(
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long,
          label: text.menuOrders,
        ),
        _NavItem(
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          label: text.menuProfile,
        ),
      ];
    } else {
      // Client or Guest
      screens = [
        const HomeScreen(),
        const ClientOrdersScreen(),
        const ProfileScreen(),
      ];
      navItems = [
        _NavItem(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          label: text.menuMain,
        ),
        _NavItem(
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long,
          label: text.menuOrders,
        ),
        _NavItem(
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          label: text.menuProfile,
        ),
      ];
    }

    // Safety check for index
    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: _PremiumBottomBar(
        items: navItems,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class _PremiumBottomBar extends StatelessWidget {
  final List<_NavItem> items;
  final int currentIndex;
  final Function(int) onTap;

  const _PremiumBottomBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
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
          currentIndex: currentIndex,
          onTap: onTap,
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
          items: items.map((item) {
            // We need to match the current index to know if this item is selected
            // But items list doesn't have index context in map directly easily without index.
            // So we iterate with usage in build or we pass selection state?
            // Since BottomNavigationBar handles selection visual via currentIndex,
            // we just need to provide the Icon (and activeIcon).

            // Wait, BottomNavigationBar expects BottomNavigationBarItem,
            // but our `items` is List<_NavItem>. We need to convert.
            return BottomNavigationBarItem(
              icon: Icon(item.icon, size: 28),
              activeIcon: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  item.selectedIcon,
                  size: 30,
                  color: AppColors.primary,
                ),
              ),
              label: item.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}
