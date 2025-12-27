import 'package:flutter/material.dart';
import 'package:ailin_tattileri_app/core/models/order_model.dart';
import 'package:ailin_tattileri_app/core/services/order_service.dart';
import 'package:ailin_tattileri_app/core/services/invoice_service.dart';
import 'package:ailin_tattileri_app/core/utils/currency_formatter.dart';
import 'package:ailin_tattileri_app/core/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:ailin_tattileri_app/l10n/app_localizations.dart';

import 'package:url_launcher/url_launcher.dart';

class AdminOrderDetailsScreen extends StatefulWidget {
  final OrderModel order;

  const AdminOrderDetailsScreen({super.key, required this.order});

  @override
  State<AdminOrderDetailsScreen> createState() =>
      _AdminOrderDetailsScreenState();
}

class _AdminOrderDetailsScreenState extends State<AdminOrderDetailsScreen> {
  late String _currentStatus;
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order.status;
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
      case 'processing':
        return Colors.orange; // Legacy
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

  void _onStatusSelected(String newStatus) {
    if (newStatus == _currentStatus) return;
    setState(() {
      _currentStatus = newStatus;
      _hasChanges = true;
    });
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await OrderService().updateOrderStatus(widget.order.id, _currentStatus);
      setState(() {
        _hasChanges = false;
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.great)),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ошибка при сохранении')));
      }
    }
  }

  Future<void> _generateInvoice() async {
    try {
      await InvoiceService().generateAndPrintInvoice(widget.order);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка создания накладной: $e')),
        );
      }
    }
  }

  Future<void> _confirmPayment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Подтвердить оплату"),
        content: Text(
          widget.order.debtAmount > 0
              ? "Подтвердить оплату ${CurrencyFormatter.format(widget.order.paidAmount)} ₸?\n\nОставшийся долг: ${CurrencyFormatter.format(widget.order.debtAmount)} ₸"
              : "Вы уверены, что хотите отметить этот заказ как оплаченный?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Отмена"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Да, оплачено"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isSaving = true);
      try {
        // Only confirm the paidAmount, keep debtAmount for later payment
        await OrderService().updatePaymentStatus(
          widget.order.id,
          widget.order.debtAmount > 0 ? 'partial' : 'paid',
          widget.order.paidAmount,
        );

        setState(() {
          _isSaving = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Оплата подтверждена")));
          Navigator.pop(context); // Go back to list to refresh
        }
      } catch (e) {
        setState(() => _isSaving = false);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Ошибка: $e")));
        }
      }
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось сделать звонок')),
        );
      }
    }
  }

  Future<void> _launchMap(String address) async {
    // Attempt to open in maps. Using a generic google maps query.
    // Encoding the query parameter is important.
    final query = Uri.encodeComponent(address);
    final Uri url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось открыть карту')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final statuses = ['new', 'cooking', 'delivering', 'completed', 'cancelled'];
    final statusColor = _getStatusColor(_currentStatus);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: statusColor,
            expandedHeight: 280,
            floating: false,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                onPressed: _generateInvoice,
                icon: const Icon(Icons.print, color: Colors.white),
                tooltip: 'Создать накладную',
              ),
              if (widget.order.paymentStatus != 'paid')
                IconButton(
                  onPressed: _confirmPayment,
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.greenAccent,
                  ),
                  tooltip: 'Подтвердить оплату',
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [statusColor, statusColor.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Current Status Icon
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          _getStatusIcon(_currentStatus),
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _getStatusText(context, _currentStatus),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.order.orderNumber ??
                            '#${widget.order.id.substring(0, 5).toUpperCase()} • ${DateFormat('dd MMM, HH:mm').format(widget.order.createdAt)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),

                      // Status Selector (Horizontal)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          child: Row(
                            children: statuses.map((status) {
                              final isSelected = status == _currentStatus;
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: InkWell(
                                  onTap: () => _onStatusSelected(status),
                                  borderRadius: BorderRadius.circular(20),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? theme.cardTheme.color
                                          : theme.colorScheme.onSurface
                                                .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: isSelected
                                          ? null
                                          : Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.2,
                                              ),
                                            ),
                                    ),
                                    child: Row(
                                      children: [
                                        if (isSelected)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              right: 6,
                                            ),
                                            child: Icon(
                                              _getStatusIcon(status),
                                              color: statusColor,
                                              size: 18,
                                            ),
                                          ),
                                        Text(
                                          _getStatusText(context, status),
                                          style: TextStyle(
                                            color: isSelected
                                                ? statusColor
                                                : Colors.white.withValues(
                                                    alpha: 0.9,
                                                  ),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                100,
              ), // Extra padding for FAB
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Debt Order Approval Section
                  if (widget.order.isPendingApproval) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.shade50,
                            Colors.orange.shade100,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.orange.shade300,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.pending_actions,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '⏳ Ожидает подтверждения',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Партнер запрашивает заказ в долг на сумму ${CurrencyFormatter.format(widget.order.debtAmount)} ₸',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isSaving
                                      ? null
                                      : () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text(
                                                'Одобрить заказ в долг?',
                                              ),
                                              content: Text(
                                                'Сумма ${CurrencyFormatter.format(widget.order.debtAmount)} ₸ будет добавлена к долгу партнера.',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: const Text('Отмена'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.green,
                                                        foregroundColor:
                                                            Colors.white,
                                                      ),
                                                  child: const Text('Одобрить'),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            setState(() => _isSaving = true);
                                            try {
                                              await OrderService()
                                                  .approveDebtOrder(
                                                    widget.order.id,
                                                  );
                                              if (mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      '✅ Заказ одобрен',
                                                    ),
                                                    backgroundColor:
                                                        Colors.green,
                                                  ),
                                                );
                                                Navigator.pop(context);
                                              }
                                            } catch (e) {
                                              setState(() => _isSaving = false);
                                              if (mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Ошибка: $e'),
                                                  ),
                                                );
                                              }
                                            }
                                          }
                                        },
                                  icon: const Icon(Icons.check_circle),
                                  label: const Text('Одобрить'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isSaving
                                      ? null
                                      : () async {
                                          final TextEditingController
                                          reasonController =
                                              TextEditingController();
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text(
                                                'Отклонить заказ?',
                                              ),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Text(
                                                    'Укажите причину отклонения (необязательно):',
                                                  ),
                                                  const SizedBox(height: 12),
                                                  TextField(
                                                    controller:
                                                        reasonController,
                                                    decoration: const InputDecoration(
                                                      hintText:
                                                          'Причина отклонения',
                                                      border:
                                                          OutlineInputBorder(),
                                                    ),
                                                    maxLines: 3,
                                                  ),
                                                ],
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: const Text('Отмена'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.red,
                                                        foregroundColor:
                                                            Colors.white,
                                                      ),
                                                  child: const Text(
                                                    'Отклонить',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            setState(() => _isSaving = true);
                                            try {
                                              await OrderService()
                                                  .rejectDebtOrder(
                                                    widget.order.id,
                                                    reason:
                                                        reasonController
                                                            .text
                                                            .isNotEmpty
                                                        ? reasonController.text
                                                        : null,
                                                  );
                                              if (mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      '❌ Заказ отклонен',
                                                    ),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                                Navigator.pop(context);
                                              }
                                            } catch (e) {
                                              setState(() => _isSaving = false);
                                              if (mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Ошибка: $e'),
                                                  ),
                                                );
                                              }
                                            }
                                          }
                                        },
                                  icon: const Icon(Icons.cancel),
                                  label: const Text('Отклонить'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Order Items Title
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 12),
                    child: Text(
                      text.menuOrders,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.5),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Photo column header
                        SizedBox(
                          width: 60,
                          child: Text(
                            'Фото',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Name column header
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Название',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        // Quantity column header
                        SizedBox(
                          width: 80,
                          child: Text(
                            'Кол-во',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Total column header
                        SizedBox(
                          width: 90,
                          child: Text(
                            'Итого',
                            textAlign: TextAlign.right,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Items List
                  ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.order.items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = widget.order.items[index];
                      // Parsing item data
                      final imageUrl = item['imageUrl'] as String? ?? '';
                      final name = item['name'] as String? ?? 'Product';
                      final quantity = item['quantity'] as int? ?? 1;
                      final price = (item['price'] as num? ?? 0).toDouble();

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Photo column
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: imageUrl.isNotEmpty
                                    ? Image.network(
                                        imageUrl,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _buildPlaceholder(),
                                      )
                                    : _buildPlaceholder(),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Name column
                            Expanded(
                              flex: 3,
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // Quantity column
                            SizedBox(
                              width: 80,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer
                                      .withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '$quantity шт',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Total price column
                            SizedBox(
                              width: 90,
                              child: Text(
                                '${CurrencyFormatter.format(price * quantity)} ₸',
                                textAlign: TextAlign.right,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Delivery Time and Comment Section
                  if (widget.order.deliveryTime != null ||
                      widget.order.comment != null) ...[
                    const SizedBox(height: 24),
                    if (widget.order.deliveryTime != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.access_time,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Желаемое время доставки",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.order.deliveryTime!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (widget.order.deliveryTime != null &&
                        widget.order.comment != null)
                      const SizedBox(height: 12),
                    if (widget.order.comment != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.comment,
                                color: Colors.orange,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Комментарий к заказу",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.order.comment!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],

                  if (widget.order.returnItems != null &&
                      widget.order.returnItems!.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.assignment_return_outlined,
                            color: Colors.red,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Возвраты",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.order.returnItems!.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = widget.order.returnItems![index];
                        final productData =
                            item['product'] as Map<String, dynamic>? ?? {};
                        final name =
                            productData['name'] as String? ?? 'Product';
                        final imageUrl =
                            productData['imageUrl'] as String? ?? '';
                        final quantity = item['quantity'] as int? ?? 1;
                        final price = (productData['price'] as num? ?? 0)
                            .toDouble();
                        final reason = item['reason'] as String? ?? 'expired';

                        String reasonText = "Срок годности";
                        if (reason == 'unsold') reasonText = "Не продано";
                        if (reason == 'damaged')
                          reasonText = "Брак/Повреждение";

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.cardTheme.color,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.1),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                        )
                                      : const Icon(
                                          Icons.fastfood,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      "Причина: $reasonText",
                                      style: TextStyle(
                                        color: Colors.red[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$quantity шт',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '-${CurrencyFormatter.format(price * quantity)} ₸',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Total Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2D3436), Color(0xFF000000)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (widget.order.refundAmount > 0) ...[
                          _buildTotalRow(
                            "Сумма заказа",
                            widget.order.totalAmount +
                                widget.order.refundAmount,
                          ),
                          const SizedBox(height: 8),
                          _buildTotalRow(
                            "Возвраты",
                            -widget.order.refundAmount,
                            isRefund: true,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(color: Colors.white24, height: 1),
                          ),
                        ],
                        Text(
                          widget.order.refundAmount > 0
                              ? "ИТОГО К ОПЛАТЕ"
                              : text.cartTotal.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${CurrencyFormatter.format(widget.order.totalAmount)} ₸',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Client Information Title
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 12),
                    child: Text(
                      "Клиент",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  // Client Information Card
                  Container(
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildBeautifulInfoRow(
                          Icons.person_rounded,
                          text.homeGreeting,
                          widget.order.userName.isNotEmpty
                              ? widget.order.userName
                              : text.homeGreeting,
                          isLast: false,
                        ),
                        _buildBeautifulInfoRow(
                          Icons.phone_rounded,
                          text.checkoutPhone,
                          widget.order.userPhone,
                          isLast: false,
                          onTap: () => _launchPhone(widget.order.userPhone),
                          trailing: const Icon(Icons.call, color: Colors.green),
                        ),
                        _buildBeautifulInfoRow(
                          Icons.location_on_rounded,
                          text.checkoutAddress,
                          widget.order.userAddress,
                          isLast: true,
                          onTap: () => _launchMap(widget.order.userAddress),
                          trailing: const Icon(Icons.map, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Payment & Delivery Information
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 12),
                    child: Text(
                      "Оплата және жеткізу",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  Container(
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Delivery Type
                        _buildBeautifulInfoRow(
                          widget.order.deliveryType == 'delivery'
                              ? Icons.delivery_dining_rounded
                              : Icons.store_rounded,
                          "Жеткізу түрі",
                          widget.order.deliveryType == 'delivery'
                              ? "Жеткізу"
                              : "Өзі алып кету",
                          isLast: false,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: widget.order.deliveryType == 'delivery'
                                  ? Colors.blue.withOpacity(0.1)
                                  : Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.order.deliveryType == 'delivery'
                                  ? "ЖЕТКІЗУ"
                                  : "САМОВЫВОЗ",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: widget.order.deliveryType == 'delivery'
                                    ? Colors.blue
                                    : Colors.purple,
                              ),
                            ),
                          ),
                        ),

                        // Payment Status
                        _buildBeautifulInfoRow(
                          widget.order.paymentStatus == 'paid'
                              ? Icons.check_circle_rounded
                              : widget.order.paymentStatus == 'partial'
                              ? Icons.pending_rounded
                              : Icons.credit_card_rounded,
                          "Төлем статусы",
                          widget.order.paymentStatus == 'paid'
                              ? "Толық төленді"
                              : widget.order.paymentStatus == 'partial'
                              ? "Ішінара төленді"
                              : "Қарызға",
                          isLast: widget.order.paymentStatus == 'paid',
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: widget.order.paymentStatus == 'paid'
                                  ? Colors.green.withOpacity(0.1)
                                  : widget.order.paymentStatus == 'partial'
                                  ? Colors.orange.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.order.paymentStatus == 'paid'
                                  ? "ТӨЛЕНДІ"
                                  : widget.order.paymentStatus == 'partial'
                                  ? "ІШІНАРА"
                                  : "ҚАРЫЗ",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: widget.order.paymentStatus == 'paid'
                                    ? Colors.green
                                    : widget.order.paymentStatus == 'partial'
                                    ? Colors.orange
                                    : Colors.red,
                              ),
                            ),
                          ),
                        ),

                        // Debt details if unpaid or partial
                        if (widget.order.paymentStatus != 'paid') ...[
                          _buildBeautifulInfoRow(
                            Icons.account_balance_wallet_rounded,
                            "Төленген сома",
                            "${CurrencyFormatter.format(widget.order.paidAmount)} ₸",
                            isLast: false,
                          ),
                          _buildBeautifulInfoRow(
                            Icons.warning_rounded,
                            "Қарыз",
                            "${CurrencyFormatter.format(widget.order.debtAmount)} ₸",
                            isLast: true,
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF3B30),
                                    Color(0xFFFF6B6B),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                "ҚАРЫЗ БАР",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // "Mark as Paid" Button in Details
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isSaving ? null : _confirmPayment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.check),
                              label: const Text("ОТМЕТИТЬ КАК ОПЛАЧЕНО"),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _hasChanges
          ? FloatingActionButton.extended(
              onPressed: _isSaving ? null : _saveChanges,
              backgroundColor: const Color(0xFF2D3436), // Premium dark color
              icon: _isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.check, color: Colors.white),
              label: Text(
                _isSaving ? 'Сохранение...' : 'Сохранить изменения',
                style: const TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildPlaceholder() {
    final theme = Theme.of(context);
    return Container(
      width: 60,
      height: 60,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(Icons.fastfood, color: theme.disabledColor, size: 28),
    );
  }

  Widget _buildBeautifulInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isLast = false,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: theme.dividerColor.withOpacity(0.1),
                  ),
                ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                  0.3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.onSurfaceVariant,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: onTap != null
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.w600,
                      decoration: onTap != null
                          ? TextDecoration.underline
                          : null,
                      decorationColor: theme.colorScheme.primary.withOpacity(
                        0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing],
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isRefund = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
        ),
        Text(
          '${amount > 0 ? "" : ""}${CurrencyFormatter.format(amount)} ₸',
          style: TextStyle(
            color: isRefund ? Colors.red[300] : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
