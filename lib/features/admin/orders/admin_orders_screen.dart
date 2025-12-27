import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ailin_tattileri_app/core/models/order_model.dart';
import 'package:ailin_tattileri_app/core/services/order_service.dart';
import 'package:ailin_tattileri_app/core/theme/app_colors.dart';
import 'package:ailin_tattileri_app/core/utils/currency_formatter.dart';

import 'package:intl/intl.dart';
import 'package:ailin_tattileri_app/l10n/app_localizations.dart';
import 'package:ailin_tattileri_app/features/admin/orders/admin_order_details_screen.dart';
import 'package:ailin_tattileri_app/features/admin/orders/admin_create_order_screen.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final orderService = OrderService();
    final text = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final dateStr = DateFormat('dd MMMM yyyy', locale).format(_selectedDate);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              '${text.menuOrders} (Admin)',
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
            ),
            Text(
              dateStr,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2024),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
            icon: Icon(Icons.calendar_month, color: theme.colorScheme.primary),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(text.dataUpdated),
                  duration: const Duration(seconds: 1),
                ),
              );
              setState(() {}); // Rebuild to refresh
            },
            icon: Icon(Icons.refresh, color: theme.iconTheme.color),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AdminCreateOrderScreen(),
            ),
          );
        },
        backgroundColor: theme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: orderService.getOrders(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data ?? [];
          final filterStatus = GoRouterState.of(
            context,
          ).uri.queryParameters['status'];

          // Filter by DATE and STATUS
          final filteredOrders = orders.where((o) {
            // 1. Date Check
            final oDate = o.createdAt;
            final isSameDay =
                oDate.year == _selectedDate.year &&
                oDate.month == _selectedDate.month &&
                oDate.day == _selectedDate.day;
            if (!isSameDay) return false;

            // 2. Status Check
            if (filterStatus != null && o.status != filterStatus) return false;

            return true;
          }).toList();

          if (filteredOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: theme.disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    text.ordersEmpty, // "No orders yet"
                    style: TextStyle(color: theme.disabledColor),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filteredOrders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = filteredOrders[index];
              return _OrderCard(order: order);
            },
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'new':
        return Colors.blue;
      case 'cooking':
        return Colors.orange;
      case 'delivering':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'processing':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(BuildContext context, String status) {
    final text = AppLocalizations.of(context)!;
    switch (status) {
      case 'new':
        return text.statusNew;
      case 'cooking':
        return text.statusCooking;
      case 'delivering':
        return text.statusDelivering;
      case 'completed':
        return text.statusCompleted;
      case 'cancelled':
        return text.statusCancelled;
      case 'processing':
        return text.statusProcessing;
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'new':
        return Icons.fiber_new;
      case 'cooking':
        return Icons.soup_kitchen;
      case 'delivering':
        return Icons.local_shipping;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AdminOrderDetailsScreen(order: order),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.userName.isNotEmpty
                          ? order.userName
                          : text.homeGreeting,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM HH:mm').format(order.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getStatusIcon(order.status),
                        size: 16,
                        color: _getStatusColor(order.status),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getStatusText(context, order.status),
                        style: TextStyle(
                          color: _getStatusColor(order.status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ), // Container closed
              ], // Row children closed
            ), // Row closed
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Info Row: Delivery Type & Payment Status
            Row(
              children: [
                // Delivery Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        order.userAddress.toLowerCase().contains('самовывоз')
                            ? Icons.store
                            : Icons.local_shipping,
                        size: 14,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        order.userAddress.toLowerCase().contains('самовывоз')
                            ? "Самовывоз"
                            : "Доставка",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Payment Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (order.paymentStatus == 'paid'
                                ? Colors.green
                                : Colors.orange)
                            .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color:
                          (order.paymentStatus == 'paid'
                                  ? Colors.green
                                  : Colors.orange)
                              .withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    order.paymentStatus == 'paid' ? "ОПЛАЧЕНО" : "НЕ ОПЛАЧЕНО",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: order.paymentStatus == 'paid'
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${order.items.length} ${text.itemsCountSuffix}", // Localized suffix
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  "${CurrencyFormatter.format(order.totalAmount)} ₸",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
