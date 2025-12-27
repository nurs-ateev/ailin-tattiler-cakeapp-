import 'package:flutter/material.dart';
import 'package:ailin_tattileri_app/core/theme/app_colors.dart';
import 'package:ailin_tattileri_app/features/desktop/dashboard/desktop_dashboard_screen.dart';
import 'package:ailin_tattileri_app/features/desktop/orders/desktop_orders_screen.dart';
import 'package:ailin_tattileri_app/features/desktop/partners/desktop_partners_screen.dart';
import 'package:ailin_tattileri_app/features/desktop/employees/desktop_employees_screen.dart';
import 'package:ailin_tattileri_app/features/desktop/clients/desktop_clients_screen.dart';
import 'package:ailin_tattileri_app/features/desktop/chat/desktop_chat_screen.dart';
import 'package:ailin_tattileri_app/features/desktop/analytics/desktop_analytics_screen.dart';
import 'package:ailin_tattileri_app/features/desktop/settings/desktop_settings_screen.dart';

class DesktopMainScreen extends StatefulWidget {
  const DesktopMainScreen({super.key});

  @override
  State<DesktopMainScreen> createState() => _DesktopMainScreenState();
}

class _DesktopMainScreenState extends State<DesktopMainScreen> {
  int _selectedIndex = 0;

  final List<_NavigationItem> _navigationItems = [
    _NavigationItem(
      icon: Icons.dashboard,
      label: 'Dashboard',
      page: const DesktopDashboardScreen(),
    ),
    _NavigationItem(
      icon: Icons.shopping_bag,
      label: 'Заказы',
      page: const DesktopOrdersScreen(),
    ),
    _NavigationItem(
      icon: Icons.warehouse,
      label: 'Склад',
      page: Scaffold(
        appBar: AppBar(title: const Text('Склад')),
        body: const Center(child: Text('🏪 Склад - В разработке')),
      ),
    ),
    _NavigationItem(
      icon: Icons.handshake,
      label: 'Партнеры',
      page: const DesktopPartnersScreen(),
    ),
    _NavigationItem(
      icon: Icons.people,
      label: 'Жұмысшылар',
      page: const DesktopEmployeesScreen(),
    ),
    _NavigationItem(
      icon: Icons.person,
      label: 'Клиенты',
      page: const DesktopClientsScreen(),
    ),
    _NavigationItem(
      icon: Icons.chat,
      label: 'Чат',
      page: const DesktopChatScreen(),
    ),
    _NavigationItem(
      icon: Icons.analytics,
      label: 'Отчеты',
      page: const DesktopAnalyticsScreen(),
    ),
    _NavigationItem(
      icon: Icons.settings,
      label: 'Настройки',
      page: const DesktopSettingsScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar Navigation
          NavigationRail(
            extended: true,
            backgroundColor: AppColors.primary,
            selectedIconTheme: const IconThemeData(color: Colors.white),
            unselectedIconTheme: IconThemeData(
              color: Colors.white.withOpacity(0.6),
            ),
            selectedLabelTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            unselectedLabelTextStyle: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
            leading: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.cake, size: 48, color: Colors.white),
                  const SizedBox(height: 8),
                  const Text(
                    'Ailin Tattileri',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Desktop Admin',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            destinations: _navigationItems
                .map(
                  (item) => NavigationRailDestination(
                    icon: Icon(item.icon),
                    label: Text(item.label),
                  ),
                )
                .toList(),
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),

          const VerticalDivider(thickness: 1, width: 1),

          // Main Content
          Expanded(child: _navigationItems[_selectedIndex].page),
        ],
      ),
    );
  }
}

class _NavigationItem {
  final IconData icon;
  final String label;
  final Widget page;

  _NavigationItem({
    required this.icon,
    required this.label,
    required this.page,
  });
}
