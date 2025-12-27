import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:ailin_tattileri_app/core/models/worker_model.dart';
import 'package:ailin_tattileri_app/core/theme/app_colors.dart';
import 'package:ailin_tattileri_app/core/services/notification_service.dart';
import 'package:ailin_tattileri_app/core/utils/currency_formatter.dart';
import 'package:ailin_tattileri_app/core/utils/input_formatters.dart';
import 'package:ailin_tattileri_app/l10n/app_localizations.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.paymentsTitle),
        backgroundColor: theme.appBarTheme.backgroundColor,
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
            icon: const Icon(Icons.calendar_month, color: AppColors.primary),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.paymentTabToPay),
            Tab(text: AppLocalizations.of(context)!.paymentTabPending),
            Tab(text: AppLocalizations.of(context)!.paymentTabHistory),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUnpaidTab(),
          _buildPendingTab(), // Now filtered
          _buildHistoryTab(), // Now filtered
        ],
      ),
    );
  }

  // --- TAB 1: Unpaid (Workers with balance > 0) ---
  Widget _buildUnpaidTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('workers')
          .where('balance', isGreaterThan: 0)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              AppLocalizations.of(
                context,
              )!.errorOccurred(snapshot.error.toString()),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final workers =
            snapshot.data?.docs.map((doc) {
              return Worker.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            }).toList() ??
            [];

        if (workers.isEmpty) {
          return _buildEmptyState(
            AppLocalizations.of(context)!.unpaidWorkersTitle,
            "", // subtitle ignored or move to arb if needed
            Icons.people_outline,
            Colors.grey,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: workers.length,
          itemBuilder: (context, index) {
            final worker = workers[index];
            return _WorkerPaymentCard(worker: worker);
          },
        );
      },
    );
  }

  // --- TAB 2: Pending Confirmation ---
  Widget _buildPendingTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('salary_payments')
          .where('status', isEqualTo: 'pending_confirmation')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(
              DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
              ),
            ),
          )
          .where(
            'date',
            isLessThan: Timestamp.fromDate(
              DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
              ).add(const Duration(days: 1)),
            ),
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _buildEmptyState(
            AppLocalizations.of(context)!.pendingPaymentsTitle,
            "",
            Icons.hourglass_empty,
            Colors.orange,
          );
        }

        // Sort locally by date desc
        docs.sort((a, b) {
          final da = (a['date'] as Timestamp).toDate();
          final db = (b['date'] as Timestamp).toDate();
          return db.compareTo(da);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final amount = (data['amount'] as num).toDouble();
            final date = (data['date'] as Timestamp).toDate();
            final workerName = data['workerName'] ?? 'Неизвестный';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  child: const Icon(
                    Icons.hourglass_empty,
                    color: Colors.orange,
                  ),
                ),
                title: Text(
                  workerName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(DateFormat('dd MMMM HH:mm', 'ru').format(date)),
                trailing: Text(
                  "${CurrencyFormatter.format(amount)} ₸",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.orange,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- TAB 3: History (Confirmed) ---
  Widget _buildHistoryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('salary_payments')
          .where('status', isEqualTo: 'confirmed')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(
              DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
              ),
            ),
          )
          .where(
            'date',
            isLessThan: Timestamp.fromDate(
              DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
              ).add(const Duration(days: 1)),
            ),
          )
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _buildEmptyState(
            AppLocalizations.of(context)!.paymentHistoryTitle,
            "",
            Icons.history,
            Colors.blue,
          );
        }

        // Sort locally
        docs.sort((a, b) {
          final da = (a['date'] as Timestamp).toDate();
          final db = (b['date'] as Timestamp).toDate();
          return db.compareTo(da);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final amount = (data['amount'] as num).toDouble();
            final date = (data['date'] as Timestamp).toDate();
            final workerName = data['workerName'] ?? 'Неизвестный';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.withOpacity(0.1),
                  child: const Icon(Icons.check, color: Colors.green),
                ),
                title: Text(
                  workerName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "Выплачено: ${DateFormat('dd MMM HH:mm', 'ru').format(date)}",
                ),
                trailing: Text(
                  "${CurrencyFormatter.format(amount)} ₸",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: color.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _WorkerPaymentCard extends StatefulWidget {
  final Worker worker;

  const _WorkerPaymentCard({required this.worker});

  @override
  State<_WorkerPaymentCard> createState() => _WorkerPaymentCardState();
}

class _WorkerPaymentCardState extends State<_WorkerPaymentCard> {
  // Stream to get pending payments
  Stream<double> _getPendingPaymentsStream() {
    return FirebaseFirestore.instance
        .collection('salary_payments')
        .where('workerId', isEqualTo: widget.worker.id)
        .where('status', isEqualTo: 'pending_confirmation')
        .snapshots()
        .map((snapshot) {
          double pending = 0;
          for (var doc in snapshot.docs) {
            pending += (doc.data()['amount'] as num).toDouble();
          }
          return pending;
        });
  }

  Future<void> _showPaymentDialog(
    BuildContext context,
    double currentDebt,
  ) async {
    final controller = TextEditingController(
      text: CurrencyFormatter.format(currentDebt),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.paymentForWorker(widget.worker.name),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(
                context,
              )!.currentDebtWithPending(CurrencyFormatter.format(currentDebt)),
            ),
            if (widget.worker.balance > currentDebt)
              Text(
                AppLocalizations.of(context)!.totalInDatabase(
                  CurrencyFormatter.format(widget.worker.balance),
                ),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.paymentAmountLabel,
                suffixText: "₸",
                border: const OutlineInputBorder(),
              ),
              inputFormatters: [CurrencyInputFormatter()],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final clean = controller.text.replaceAll(RegExp(r'\s+'), '');
              final amount = double.tryParse(clean);
              if (amount != null && amount > 0) {
                Navigator.pop(context, amount);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(
              AppLocalizations.of(context)!.payButton,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (result != null) {
      await _processPayment(context, result);
    }
  }

  Future<void> _processPayment(BuildContext context, double amount) async {
    try {
      // 1. Create Transaction Record
      await FirebaseFirestore.instance.collection('salary_payments').add({
        'workerId': widget.worker.id,
        'workerName': widget.worker.name,
        'amount': amount,
        'date': Timestamp.now(),
        'status': 'pending_confirmation', // Waiting for worker to confirm
        'processedBy': 'admin',
      });

      // 2. Worker Balance will be decremented upon Worker Confirmation

      // 3. Send Notification
      await NotificationService().sendNotification(
        receiverId: widget.worker.id,
        title: AppLocalizations.of(context)!.paymentSentNotificationTitle,
        body: AppLocalizations.of(
          context,
        )!.paymentSentNotificationBody(CurrencyFormatter.format(amount)),
        type:
            "payment_confirmation", // Special type to open confirmation screen
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.paymentSentSuccess(
                CurrencyFormatter.format(amount),
                widget.worker.name,
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorOccurred(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<double>(
      stream: _getPendingPaymentsStream(),
      initialData: 0.0,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LinearProgressIndicator());
        }

        final pendingAmount = snapshot.data ?? 0.0;
        final actualDebt = widget.worker.balance - pendingAmount;

        // If debt is 0 or less (considering pending payments), hide the card
        if (actualDebt <= 0) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    widget.worker.name[0],
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.worker.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        widget.worker.position,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 14,
                        ),
                      ),
                      if (pendingAmount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            AppLocalizations.of(
                              context,
                            )!.pendingConfirmationLabel(
                              CurrencyFormatter.format(pendingAmount),
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${CurrencyFormatter.format(actualDebt)} ₸",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.redAccent,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showPaymentDialog(context, actualDebt),
                      child: Text(AppLocalizations.of(context)!.payButton),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
