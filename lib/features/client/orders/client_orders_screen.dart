import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ailin_tattileri_app/core/models/order_model.dart';
import 'package:ailin_tattileri_app/core/services/order_service.dart';
import 'package:ailin_tattileri_app/core/services/auth_service.dart';
import 'package:ailin_tattileri_app/core/theme/app_colors.dart';
import 'package:ailin_tattileri_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:ailin_tattileri_app/features/client/orders/client_order_details_screen.dart';

class ClientOrdersScreen extends StatelessWidget {
  const ClientOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService(); // Get current user
    final orderService = OrderService();
    final text = AppLocalizations.of(context)!;
    final user = authService.currentUser;
    final theme = Theme.of(context);

    if (user == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(title: Text(text.menuOrders)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                "Войдите, чтобы видеть заказы", // Localize later
                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.push('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Войти"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(text.menuOrders),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: orderService.getUserOrders(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // Often index error first time
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    text.ordersEmpty,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final order = orders[index];
              return _ClientOrderCard(order: order);
            },
          );
        },
      ),
    );
  }
}

class _ClientOrderCard extends StatelessWidget {
  final OrderModel order;

  const _ClientOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dateStr = DateFormat('dd MMM HH:mm').format(order.createdAt);

    // Status translation map
    String statusText = order.status;
    Color statusColor = Colors.grey;

    switch (order.status) {
      case 'new':
        statusText = text.statusNew;
        statusColor = Colors.blue;
        break;
      case 'accepted':
        statusText = text.statusAccepted;
        statusColor = Colors.orange;
        break;
      case 'cooking':
        statusText = text.statusCooking;
        statusColor = Colors.orangeAccent;
        break;
      case 'delivering':
        statusText = text.statusDelivering;
        statusColor = Colors.indigo;
        break;
      case 'completed':
        statusText = text.statusCompleted;
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusText = text.statusCancelled;
        statusColor = Colors.red;
        break;
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClientOrderDetailsScreen(order: order),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "${order.items.length} тауар • ${order.totalAmount.toInt()} ₸",
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Толығырақ',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
