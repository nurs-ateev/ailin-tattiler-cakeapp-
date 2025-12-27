import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ailin_tattileri_app/core/models/order_model.dart';
import 'package:ailin_tattileri_app/core/utils/currency_formatter.dart';
import 'package:ailin_tattileri_app/features/desktop/orders/desktop_order_details_dialog.dart';
import 'package:intl/intl.dart';

class DesktopOrdersScreen extends StatefulWidget {
  const DesktopOrdersScreen({super.key});

  @override
  State<DesktopOrdersScreen> createState() => _DesktopOrdersScreenState();
}

class _DesktopOrdersScreenState extends State<DesktopOrdersScreen> {
  String _selectedStatus = 'all';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление заказами'),
        actions: [
          // Search
          SizedBox(
            width: 300,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Поиск по номеру, клиенту...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Sidebar Filters
          Container(
            width: 250,
            color: Colors.grey[100],
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Фильтры',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _FilterButton(
                  label: 'Все заказы',
                  icon: Icons.list,
                  isSelected: _selectedStatus == 'all',
                  onTap: () => setState(() => _selectedStatus = 'all'),
                ),
                _FilterButton(
                  label: 'Новые',
                  icon: Icons.fiber_new,
                  isSelected: _selectedStatus == 'new',
                  color: Colors.blue,
                  onTap: () => setState(() => _selectedStatus = 'new'),
                ),
                _FilterButton(
                  label: 'Готовится',
                  icon: Icons.soup_kitchen,
                  isSelected: _selectedStatus == 'cooking',
                  color: Colors.orange,
                  onTap: () => setState(() => _selectedStatus = 'cooking'),
                ),
                _FilterButton(
                  label: 'В пути',
                  icon: Icons.local_shipping,
                  isSelected: _selectedStatus == 'delivering',
                  color: Colors.purple,
                  onTap: () => setState(() => _selectedStatus = 'delivering'),
                ),
                _FilterButton(
                  label: 'Завершено',
                  icon: Icons.check_circle,
                  isSelected: _selectedStatus == 'completed',
                  color: Colors.green,
                  onTap: () => setState(() => _selectedStatus = 'completed'),
                ),
                _FilterButton(
                  label: 'Отменено',
                  icon: Icons.cancel,
                  isSelected: _selectedStatus == 'cancelled',
                  color: Colors.red,
                  onTap: () => setState(() => _selectedStatus = 'cancelled'),
                ),
              ],
            ),
          ),

          // Orders List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Нет заказов'));
                }

                var orders = snapshot.data!.docs
                    .map(
                      (doc) => OrderModel.fromMap(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      ),
                    )
                    .toList();

                // Apply filters
                if (_selectedStatus != 'all') {
                  orders = orders
                      .where((o) => o.status == _selectedStatus)
                      .toList();
                }

                if (_searchQuery.isNotEmpty) {
                  orders = orders.where((o) {
                    final orderNumber = (o.orderNumber ?? '').toLowerCase();
                    final userName = o.userName.toLowerCase();
                    final phone = o.userPhone.toLowerCase();
                    return orderNumber.contains(_searchQuery) ||
                        userName.contains(_searchQuery) ||
                        phone.contains(_searchQuery);
                  }).toList();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: _getStatusColor(
                            order.status,
                          ).withOpacity(0.2),
                          child: Icon(
                            _getStatusIcon(order.status),
                            color: _getStatusColor(order.status),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              order.orderNumber ??
                                  '#${order.id.substring(0, 8)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  order.status,
                                ).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _getStatusText(order.status),
                                style: TextStyle(
                                  color: _getStatusColor(order.status),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (order.isPendingApproval) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Ожидает одобрения',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              '👤 ${order.userName} • 📞 ${order.userPhone}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '📍 ${order.userAddress}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '🕐 ${DateFormat('dd MMM yyyy, HH:mm').format(order.createdAt)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${CurrencyFormatter.format(order.totalAmount)} ₸',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getPaymentStatusText(order.paymentStatus),
                              style: TextStyle(
                                fontSize: 12,
                                color: _getPaymentStatusColor(
                                  order.paymentStatus,
                                ),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) =>
                                DesktopOrderDetailsDialog(order: order),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

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
      default:
        return Colors.grey;
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
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'new':
        return 'Новый';
      case 'cooking':
        return 'Готовится';
      case 'delivering':
        return 'В пути';
      case 'completed':
        return 'Завершен';
      case 'cancelled':
        return 'Отменен';
      default:
        return status;
    }
  }

  String _getPaymentStatusText(String status) {
    switch (status) {
      case 'paid':
        return 'Оплачено';
      case 'unpaid':
        return 'Не оплачено';
      case 'partial':
        return 'Частично';
      default:
        return status;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'unpaid':
        return Colors.red;
      case 'partial':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected
            ? (color ?? Colors.blue).withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? (color ?? Colors.blue) : Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? (color ?? Colors.blue)
                        : Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
