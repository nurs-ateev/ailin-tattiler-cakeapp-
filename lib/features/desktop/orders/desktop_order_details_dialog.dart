import 'package:flutter/material.dart';
import 'package:ailin_tattileri_app/core/models/order_model.dart';
import 'package:ailin_tattileri_app/core/services/order_service.dart';
import 'package:ailin_tattileri_app/core/utils/currency_formatter.dart';
import 'package:intl/intl.dart';

class DesktopOrderDetailsDialog extends StatefulWidget {
  final OrderModel order;

  const DesktopOrderDetailsDialog({super.key, required this.order});

  @override
  State<DesktopOrderDetailsDialog> createState() =>
      _DesktopOrderDetailsDialogState();
}

class _DesktopOrderDetailsDialogState extends State<DesktopOrderDetailsDialog> {
  final OrderService _orderService = OrderService();
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order.status;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  widget.order.orderNumber ??
                      '#${widget.order.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Info
                    _SectionTitle(title: 'Информация о клиенте'),
                    _InfoRow(label: 'Имя', value: widget.order.userName),
                    _InfoRow(label: 'Телефон', value: widget.order.userPhone),
                    _InfoRow(label: 'Адрес', value: widget.order.userAddress),
                    _InfoRow(
                      label: 'Дата заказа',
                      value: DateFormat(
                        'dd MMM yyyy, HH:mm',
                      ).format(widget.order.createdAt),
                    ),

                    const SizedBox(height: 24),

                    // Order Items
                    _SectionTitle(title: 'Состав заказа'),
                    ...widget.order.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item['name']} x ${item['quantity']}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            Text(
                              '${CurrencyFormatter.format(item['price'] * item['quantity'])} ₸',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const Divider(),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Итого:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '${CurrencyFormatter.format(widget.order.totalAmount)} ₸',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Payment Info
                    _SectionTitle(title: 'Оплата'),
                    _InfoRow(
                      label: 'Статус оплаты',
                      value: _getPaymentStatusText(widget.order.paymentStatus),
                    ),
                    if (widget.order.paidAmount > 0)
                      _InfoRow(
                        label: 'Оплачено',
                        value:
                            '${CurrencyFormatter.format(widget.order.paidAmount)} ₸',
                      ),
                    if (widget.order.debtAmount > 0)
                      _InfoRow(
                        label: 'Долг',
                        value:
                            '${CurrencyFormatter.format(widget.order.debtAmount)} ₸',
                      ),

                    const SizedBox(height: 24),

                    // Status Change
                    _SectionTitle(title: 'Статус заказа'),
                    DropdownButtonFormField<String>(
                      value: _currentStatus,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'new', child: Text('Новый')),
                        DropdownMenuItem(
                          value: 'cooking',
                          child: Text('Готовится'),
                        ),
                        DropdownMenuItem(
                          value: 'delivering',
                          child: Text('В пути'),
                        ),
                        DropdownMenuItem(
                          value: 'completed',
                          child: Text('Завершен'),
                        ),
                        DropdownMenuItem(
                          value: 'cancelled',
                          child: Text('Отменен'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _currentStatus = value;
                          });
                        }
                      },
                    ),

                    if (widget.order.comment != null &&
                        widget.order.comment!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _SectionTitle(title: 'Комментарий'),
                      Text(widget.order.comment!),
                    ],
                  ],
                ),
              ),
            ),

            const Divider(),

            // Actions
            Row(
              children: [
                if (widget.order.paymentStatus != 'paid')
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _confirmPayment();
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Подтвердить оплату'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    await _updateStatus();
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Сохранить статус'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Print receipt
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Печать чека...')),
                    );
                  },
                  icon: const Icon(Icons.print),
                  label: const Text('Печать чека'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus() async {
    try {
      await _orderService.updateOrderStatus(widget.order.id, _currentStatus);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Статус обновлен')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  Future<void> _confirmPayment() async {
    try {
      await _orderService.updatePaymentStatus(
        widget.order.id,
        widget.order.debtAmount > 0 ? 'partial' : 'paid',
        widget.order.paidAmount > 0
            ? widget.order.paidAmount
            : widget.order.totalAmount,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Оплата подтверждена')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  String _getPaymentStatusText(String status) {
    switch (status) {
      case 'paid':
        return 'Оплачено';
      case 'unpaid':
        return 'Не оплачено';
      case 'partial':
        return 'Частично оплачено';
      default:
        return status;
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
