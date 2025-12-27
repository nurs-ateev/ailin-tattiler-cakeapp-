import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ailin_tattileri_app/core/models/order_model.dart';
import 'package:ailin_tattileri_app/core/theme/app_colors.dart';
import 'package:ailin_tattileri_app/features/common/notifications/notification_button.dart';
import 'package:ailin_tattileri_app/l10n/app_localizations.dart';
import 'package:ailin_tattileri_app/features/admin/chat/admin_chat_list_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // Drawer removed - using BottomNavigationBar shell
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.adminDashboardTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: const [
          NotificationButton(userId: 'admin'),
          SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Ошибка: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final orders =
              snapshot.data?.docs
                  .map(
                    (doc) => OrderModel.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList() ??
              [];

          // Calculate statistics
          final newOrders = orders.where((o) => o.status == 'new').length;
          final cookingOrders = orders
              .where((o) => o.status == 'cooking')
              .length;
          final completedOrders = orders
              .where((o) => o.status == 'completed')
              .length;
          final deliveringOrders = orders
              .where((o) => o.status == 'delivering')
              .length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Statistics Cards
                Row(
                  children: [
                    Expanded(
                      child: _PremiumStatCard(
                        title: AppLocalizations.of(context)!.statNewOrders,
                        value: "$newOrders",
                        icon: Icons.shopping_bag_outlined,
                        colors: const [Color(0xFF2563EB), Color(0xFF60A5FA)],
                        onTap: () => context.push(
                          Uri(
                            path: '/admin/orders',
                            queryParameters: {'status': 'new'},
                          ).toString(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PremiumStatCard(
                        title: "Готовится",
                        value: "$cookingOrders",
                        icon: Icons.soup_kitchen,
                        colors: const [Color(0xFFD97706), Color(0xFFFBBF24)],
                        onTap: () => context.push(
                          Uri(
                            path: '/admin/orders',
                            queryParameters: {'status': 'cooking'},
                          ).toString(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _PremiumStatCard(
                        title: "Завершено",
                        value: "$completedOrders",
                        icon: Icons.check_circle_outline,
                        colors: const [Color(0xFF059669), Color(0xFF34D399)],
                        onTap: () => context.push(
                          Uri(
                            path: '/admin/orders',
                            queryParameters: {'status': 'completed'},
                          ).toString(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PremiumStatCard(
                        title: "В пути",
                        value: "$deliveringOrders",
                        icon: Icons.local_shipping,
                        colors: const [Color(0xFF7C3AED), Color(0xFFA78BFA)],
                        onTap: () => context.push(
                          Uri(
                            path: '/admin/orders',
                            queryParameters: {'status': 'delivering'},
                          ).toString(),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Quick Actions Grid
                Text(
                  AppLocalizations.of(context)!.quickActions,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                Column(
                  children: [
                    _PremiumListActionCard(
                      title: AppLocalizations.of(context)!.actionManageOrders,
                      subtitle: AppLocalizations.of(
                        context,
                      )!.actionManageOrdersSubtitle,
                      icon: Icons.list_alt,
                      colors: const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                      onTap: () => context.push('/admin/orders'),
                    ),
                    const SizedBox(height: 12),

                    _PremiumListActionCard(
                      title: AppLocalizations.of(context)!.actionManageMenu,
                      subtitle: AppLocalizations.of(
                        context,
                      )!.actionManageMenuSubtitle,
                      icon: Icons.restaurant_menu,
                      colors: const [Color(0xFFF97316), Color(0xFFFDBA74)],
                      onTap: () => context.push('/admin/products'),
                    ),
                    const SizedBox(height: 12),

                    _PremiumListActionCard(
                      title: "Чат с клиентами",
                      subtitle: "Сообщения от клиентов",
                      icon: Icons.chat,
                      colors: const [Color(0xFF14B8A6), Color(0xFF5EEAD4)],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminChatListScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _PremiumListActionCard(
                      title:
                          Localizations.localeOf(context).languageCode == 'kk'
                          ? "Санаттар"
                          : "Категории",
                      subtitle:
                          Localizations.localeOf(context).languageCode == 'kk'
                          ? "Санаттарды басқару"
                          : "Управление категориями",
                      icon: Icons.category,
                      colors: const [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                      onTap: () => context.push('/admin/categories'),
                    ),
                    const SizedBox(height: 12),

                    _PremiumListActionCard(
                      title:
                          Localizations.localeOf(context).languageCode == 'kk'
                          ? "Қарыздар"
                          : "Долги",
                      subtitle:
                          Localizations.localeOf(context).languageCode == 'kk'
                          ? "Дебиторлық қарыз"
                          : "Управление долгами",
                      icon: Icons.account_balance_wallet,
                      colors: const [Color(0xFFEF4444), Color(0xFFF87171)],
                      onTap: () => context.push('/admin/debts'),
                    ),
                    const SizedBox(height: 12),

                    _PremiumListActionCard(
                      title: AppLocalizations.of(context)!.actionPayments,
                      subtitle: AppLocalizations.of(
                        context,
                      )!.actionPaymentsSubtitle,
                      icon: Icons.payment,
                      colors: const [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
                      onTap: () => context.push('/admin/payments'),
                    ),
                    const SizedBox(height: 12),

                    _PremiumListActionCard(
                      title: AppLocalizations.of(context)!.actionAdvance,
                      subtitle: AppLocalizations.of(
                        context,
                      )!.actionAdvanceSubtitle,
                      icon: Icons.wallet,
                      colors: const [Color(0xFF10B981), Color(0xFF34D399)],
                      onTap: () => context.push('/admin/advance'),
                    ),
                    const SizedBox(height: 12),

                    _PremiumListActionCard(
                      title: AppLocalizations.of(context)!.actionWarehouse,
                      subtitle: AppLocalizations.of(
                        context,
                      )!.actionWarehouseSubtitle,
                      icon: Icons.inventory_2,
                      colors: const [Color(0xFFD97706), Color(0xFFFBBF24)],
                      onTap: () => context.push('/admin/warehouse'),
                    ),
                    const SizedBox(height: 12),

                    _PremiumListActionCard(
                      title: AppLocalizations.of(context)!.actionExpenses,
                      subtitle: AppLocalizations.of(
                        context,
                      )!.actionExpensesSubtitle,
                      icon: Icons.money_off,
                      colors: const [Color(0xFFE11D48), Color(0xFFFB7185)],
                      onTap: () => context.push('/admin/expenses'),
                    ),
                    const SizedBox(height: 12),

                    _PremiumListActionCard(
                      title: AppLocalizations.of(context)!.actionAnalytics,
                      subtitle: AppLocalizations.of(
                        context,
                      )!.actionAnalyticsSubtitle,
                      icon: Icons.analytics,
                      colors: const [Color(0xFF6366F1), Color(0xFF818CF8)],
                      onTap: () => context.push('/admin/analytics'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Statistics Card Widget
class _PremiumStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback? onTap;

  const _PremiumStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.colors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const Spacer(),
                // Optional: visual indicator or decorator
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Premium Action List Item (Restored "Previous Version" Layout but Beautiful)
class _PremiumListActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  const _PremiumListActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Gradient Icon Container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colors.first.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(
                        0.6,
                      ),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: theme.iconTheme.color?.withOpacity(0.5) ?? Colors.grey,
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
