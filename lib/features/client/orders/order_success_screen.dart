import 'package:ailin_tattileri_app/core/models/order_model.dart';
import 'package:ailin_tattileri_app/core/theme/app_colors.dart';
import 'package:ailin_tattileri_app/core/utils/currency_formatter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class OrderSuccessScreen extends StatelessWidget {
  final OrderModel order;
  final String userRole;

  const OrderSuccessScreen({
    super.key,
    required this.order,
    this.userRole = 'client',
  });

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final isKazakh = languageCode == 'kk';

    final t = isKazakh ? _kk : _ru;

    final isPickup =
        order.userAddress.contains('Самовывоз') ||
        order.deliveryType == 'pickup';
    final formattedDate =
        order.deliveryTime ??
        DateFormat('dd MMM, HH:mm').format(order.createdAt);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/home'), // Go home
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Success Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                t['orderPlaced']!,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              if (isPickup)
                Text(
                  t['orderPaymentUponPickup']!,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                ),
              const SizedBox(height: 32),

              // Order Details Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildRow(
                      t['orderNumber']!,
                      order.orderNumber ??
                          "#${order.id.length >= 5 ? order.id.substring(0, 5).toUpperCase() : order.id.toUpperCase()}",
                    ),
                    const Divider(height: 24),
                    _buildRow(
                      t['orderStatus']!,
                      t['orderStatusAwaitingPayment']!,
                      valueColor: Colors.orange,
                    ),
                    const Divider(height: 24),
                    _buildRow(
                      t['deliveryType']!,
                      isPickup ? t['pickup']! : t['delivery']!,
                      icon: isPickup ? Icons.store : Icons.local_shipping,
                    ),
                    const Divider(height: 24),
                    _buildRow(
                      isPickup ? t['pickupPoint']! : t['deliveryAddress']!,
                      order.userAddress,
                      isMultiLine: true,
                    ),
                    const Divider(height: 24),
                    _buildRow(
                      isPickup ? t['readiness']! : t['deliveryTime']!,
                      formattedDate,
                    ),
                    const Divider(height: 24),
                    _buildRow(
                      t['totalAmount']!,
                      "${CurrencyFormatter.format(order.totalAmount)} ₸",
                      isBold: true,
                      valueColor: AppColors.primary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Determine orders tab index based on role
                    // Client: Tab 1
                    // Partner: Tab 2
                    // Admin: Tab 3 (but admins probably don't order this way often)
                    final tabIndex = (userRole == 'partner') ? 2 : 1;
                    context.go('/home?tab=$tabIndex');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    t['goToMyOrders']!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/home'),
                child: Text(
                  t['returnToMain']!,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const Map<String, String> _ru = {
    'orderPlaced': "Заказ оформлен!",
    'orderPaymentUponPickup':
        "Оплата производится при получении заказа в точке самовывоза",
    'orderNumber': "Номер заказа",
    'orderStatus': "Статус",
    'orderStatusAwaitingPayment': "Ожидает оплаты",
    'deliveryType': "Тип доставки",
    'pickup': "Самовывоз",
    'delivery': "Доставка",
    'pickupPoint': "Точка самовывоза",
    'deliveryAddress': "Адрес доставки",
    'readiness': "Готовность",
    'deliveryTime': "Время доставки",
    'totalAmount': "Итоговая сумма",
    'goToMyOrders': "Перейти к моим заказам",
    'returnToMain': "Вернуться на главную",
  };

  static const Map<String, String> _kk = {
    'orderPlaced': "Тапсырыс қабылданды!",
    'orderPaymentUponPickup':
        "Төлем тапсырысты алып кету нүктесінде қабылдаған кезде жасалады",
    'orderNumber': "Тапсырыс нөмірі",
    'orderStatus': "Статус",
    'orderStatusAwaitingPayment': "Төлем күтілуде",
    'deliveryType': "Жеткізу түрі",
    'pickup': "Алып кету",
    'delivery': "Жеткізу",
    'pickupPoint': "Алып кету нүктесі",
    'deliveryAddress': "Жеткізу мекенжайы",
    'readiness': "Дайындығы",
    'deliveryTime': "Жеткізу уақыты",
    'totalAmount': "Жалпы сома",
    'goToMyOrders': "Менің тапсырыстарыма өту",
    'returnToMain': "Басты бетке оралу",
  };

  Widget _buildRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
    bool isMultiLine = false,
    IconData? icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: valueColor ?? Colors.black87),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: valueColor ?? Colors.black87,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: isMultiLine ? 3 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
