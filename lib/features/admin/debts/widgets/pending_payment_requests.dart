import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ailin_tattileri_app/core/models/payment_history_model.dart';
import 'package:ailin_tattileri_app/core/models/order_model.dart';
import 'package:ailin_tattileri_app/core/services/debt_service.dart';
import 'package:ailin_tattileri_app/core/utils/currency_formatter.dart';
import 'package:intl/intl.dart';

class PendingPaymentRequestsWidget extends StatelessWidget {
  const PendingPaymentRequestsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final debtService = DebtService();

    return StreamBuilder<List<PaymentHistoryModel>>(
      stream: debtService.getPendingPaymentRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: Colors.green[400],
                ),
                const SizedBox(height: 16),
                Text(
                  Localizations.localeOf(context).languageCode == 'kk'
                      ? "Растауды күтетін өтініштер жоқ"
                      : "Нет заявок ожидающих подтверждения",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  Localizations.localeOf(context).languageCode == 'kk'
                      ? "Барлық өтініштер өңделді"
                      : "Все заявки обработаны",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final requests = snapshot.data!;

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade400, Colors.orange.shade600],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Orange header section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.orange.shade600],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.notifications_active,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Localizations.localeOf(context).languageCode == 'kk'
                                ? "Төлем өтініштері"
                                : "Заявки на оплату",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            Localizations.localeOf(context).languageCode == 'kk'
                                ? "${requests.length} күтуде"
                                : "${requests.length} ожидают",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // White cards section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: requests
                      .map((request) => _PaymentRequestCard(request: request))
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PaymentRequestCard extends StatelessWidget {
  final PaymentHistoryModel request;

  const _PaymentRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('orders')
          .doc(request.orderId)
          .get(),
      builder: (context, orderSnapshot) {
        if (!orderSnapshot.hasData) {
          return const SizedBox.shrink();
        }

        final order = OrderModel.fromMap(
          orderSnapshot.data!.data() as Map<String, dynamic>,
          orderSnapshot.data!.id,
        );

        // Get partner info
        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('partners')
              .where('userId', isEqualTo: order.userId)
              .limit(1)
              .get(),
          builder: (context, partnerSnapshot) {
            String partnerName = "Загрузка...";
            if (partnerSnapshot.hasData &&
                partnerSnapshot.data!.docs.isNotEmpty) {
              final partnerData =
                  partnerSnapshot.data!.docs.first.data()
                      as Map<String, dynamic>;
              partnerName = partnerData['name'] ?? 'Неизвестно';
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with partner name
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.shade50,
                          Colors.orange.shade100.withOpacity(0.3),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.business_rounded,
                            color: Colors.orange,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                partnerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat(
                                  'dd.MM.yyyy, HH:mm',
                                ).format(request.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Body with order and payment info
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order info
                        Row(
                          children: [
                            Flexible(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.receipt_long,
                                    size: 18,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      Localizations.localeOf(
                                                context,
                                              ).languageCode ==
                                              'kk'
                                          ? "Тапсырыс #${order.id.substring(0, 5).toUpperCase()}"
                                          : "Заказ #${order.id.substring(0, 5).toUpperCase()}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                Localizations.localeOf(context).languageCode ==
                                        'kk'
                                    ? "Қарыз: ${CurrencyFormatter.format(order.debtAmount)} ₸"
                                    : "Долг: ${CurrencyFormatter.format(order.debtAmount)} ₸",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Payment amount - BIG
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.shade400,
                                Colors.orange.shade500,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  Localizations.localeOf(
                                            context,
                                          ).languageCode ==
                                          'kk'
                                      ? "Төлем сомасы:"
                                      : "Сумма оплаты:",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  "${CurrencyFormatter.format(request.amount)} ₸",
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (request.note != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.comment_outlined,
                                  size: 18,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    request.note!,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Action buttons - Two rows
                        Column(
                          children: [
                            // First row: Edit and Approve
                            Row(
                              children: [
                                // Edit button - icon only
                                OutlinedButton(
                                  onPressed: () =>
                                      _editAmount(context, request, order),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.orange,
                                    side: BorderSide(
                                      color: Colors.orange.shade400,
                                      width: 2,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.edit_rounded,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _approveRequest(context, request),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      elevation: 3,
                                      shadowColor: Colors.green.withOpacity(
                                        0.4,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            Localizations.localeOf(
                                                      context,
                                                    ).languageCode ==
                                                    'kk'
                                                ? "Растау"
                                                : "ОК",
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Second row: Reject (full width)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () =>
                                    _rejectRequest(context, request),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: BorderSide(
                                    color: Colors.red.shade300,
                                    width: 2,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.cancel_rounded, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      Localizations.localeOf(
                                                context,
                                              ).languageCode ==
                                              'kk'
                                          ? "Қабылдамау"
                                          : "Отклонить",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _editAmount(
    BuildContext context,
    PaymentHistoryModel request,
    OrderModel order,
  ) async {
    final amountController = TextEditingController(
      text: request.amount.toStringAsFixed(0),
    );

    final newAmount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.edit_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text(
              Localizations.localeOf(context).languageCode == 'kk'
                  ? "Соманы түзету"
                  : "Изменить сумму",
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Долг: ${order.debtAmount.toStringAsFixed(0)} ₸",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: Localizations.localeOf(context).languageCode == 'kk'
                    ? "Төлем сомасы"
                    : "Сумма оплаты",
                hintText: Localizations.localeOf(context).languageCode == 'kk'
                    ? "Мысалы: 5000"
                    : "Пример: 5000",
                suffixText: "₸",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.orange, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              Localizations.localeOf(context).languageCode == 'kk'
                  ? "Болдырмау"
                  : "Отмена",
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              Navigator.pop(context, amount);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              Localizations.localeOf(context).languageCode == 'kk'
                  ? "Сақтау"
                  : "Сохранить",
            ),
          ),
        ],
      ),
    );

    if (newAmount != null && newAmount > 0 && context.mounted) {
      try {
        // Update the payment request amount
        await FirebaseFirestore.instance
            .collection('payment_history')
            .doc(request.id)
            .update({'amount': newAmount});

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Localizations.localeOf(context).languageCode == 'kk'
                    ? "Сома түзетілді!"
                    : "Сумма изменена!",
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Ошибка: $e")));
        }
      }
    }
  }

  Future<void> _approveRequest(
    BuildContext context,
    PaymentHistoryModel request,
  ) async {
    try {
      final debtService = DebtService();
      await debtService.approvePaymentRequest(request.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'kk'
                  ? "Төлем расталды!"
                  : "Оплата подтверждена!",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Ошибка: $e")));
      }
    }
  }

  Future<void> _rejectRequest(
    BuildContext context,
    PaymentHistoryModel request,
  ) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          Localizations.localeOf(context).languageCode == 'kk'
              ? "Өтінішті қабылдамау"
              : "Отклонить заявку",
        ),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(
            labelText: Localizations.localeOf(context).languageCode == 'kk'
                ? "Себебі (міндетті емес)"
                : "Причина (необязательно)",
            hintText: Localizations.localeOf(context).languageCode == 'kk'
                ? "Мысалы: Төлем расталмады"
                : "Пример: Оплата не подтверждена",
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              Localizations.localeOf(context).languageCode == 'kk'
                  ? "Болдырмау"
                  : "Отмена",
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              Localizations.localeOf(context).languageCode == 'kk'
                  ? "Қабылдамау"
                  : "Отклонить",
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final debtService = DebtService();
        await debtService.rejectPaymentRequest(
          request.id,
          reasonController.text.isNotEmpty ? reasonController.text : null,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Localizations.localeOf(context).languageCode == 'kk'
                    ? "Өтініш қабылданбады"
                    : "Заявка отклонена",
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Ошибка: $e")));
        }
      }
    }
  }
}
