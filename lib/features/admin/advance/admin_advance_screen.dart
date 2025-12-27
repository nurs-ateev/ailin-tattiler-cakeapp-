import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:ailin_tattileri_app/core/models/worker_model.dart';
import 'package:ailin_tattileri_app/core/theme/app_colors.dart';
import 'package:ailin_tattileri_app/core/utils/input_formatters.dart';
import 'package:ailin_tattileri_app/core/services/notification_service.dart';
import 'package:ailin_tattileri_app/core/utils/currency_formatter.dart';
import 'package:go_router/go_router.dart';
import 'package:ailin_tattileri_app/l10n/app_localizations.dart';

class AdminAdvanceScreen extends StatefulWidget {
  const AdminAdvanceScreen({super.key});

  @override
  State<AdminAdvanceScreen> createState() => _AdminAdvanceScreenState();
}

class _AdminAdvanceScreenState extends State<AdminAdvanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- LOGIC: Give Advance ---
  void _showAdvanceDialog(Worker worker) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing while loading
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final text = AppLocalizations.of(context)!;
          return AlertDialog(
            title: Text(
              AppLocalizations.of(context)!.advanceForWorker(worker.name),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("${text.workerName}: ${worker.name}"),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: text.amountLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: text.noteLabelOptional,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancelButton),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final cleanAmount = amountController.text.replaceAll(
                          RegExp(r'\s+'),
                          '',
                        );
                        final amount = double.tryParse(cleanAmount);

                        if (amount == null || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(context)!.enterValidAmount,
                              ),
                            ),
                          );
                          return;
                        }

                        setState(() => isLoading = true);

                        try {
                          // Create advance request (Pending)
                          await FirebaseFirestore.instance
                              .collection('advance_requests')
                              .add({
                                'workerId': worker.id,
                                'workerName': worker.name,
                                'amount': amount,
                                'requestDate': Timestamp.now(),
                                'status': 'pending',
                                'note': noteController.text.trim().isEmpty
                                    ? null
                                    : noteController.text.trim(),
                              });

                          // Decrease Worker Balance logic removed: we will deduct upon 'Repayment from Salary' instead.

                          // Send Notification (non-blocking try-catch inside service but we await it)
                          await NotificationService().sendNotification(
                            receiverId: worker.id,
                            title: AppLocalizations.of(
                              context,
                            )!.advanceIssuedNotificationTitle,
                            body: AppLocalizations.of(context)!
                                .advanceIssuedNotificationBody(
                                  CurrencyFormatter.format(amount),
                                ),
                            type: 'advance',
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.advanceRequestSent(worker.name),
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            setState(() => isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.errorOccurred(e.toString()),
                                ),
                              ),
                            );
                          }
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(AppLocalizations.of(context)!.giveButton),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- LOGIC: Repayment Dialog ---
  void _showRepaymentDialog(String workerId, String workerName) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    String method = 'salary';
    String salaryOption = 'smart_auto';

    double? foundedDailySalary;
    double? currentDebt;
    double? currentBalance;
    bool isLoading = false;
    String? statusMessage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          if (currentDebt == null && !isLoading) {
            isLoading = true;
            Future.wait([
              // 1. Fetch Debt
              FirebaseFirestore.instance
                  .collection('advance_requests')
                  .where('workerId', isEqualTo: workerId)
                  .get()
                  .then((advances) async {
                    double taken = 0;
                    for (var doc in advances.docs) {
                      final status = doc['status'];
                      if (status == 'accepted' || status == 'pending') {
                        taken += (doc['amount'] as num).toDouble();
                      }
                    }

                    final repayments = await FirebaseFirestore.instance
                        .collection('advance_repayments')
                        .where('workerId', isEqualTo: workerId)
                        .get();

                    double repaid = 0;
                    for (var doc in repayments.docs)
                      repaid += (doc['amount'] as num).toDouble();

                    return taken - repaid;
                  }),
              // 2. Fetch Today Salary
              FirebaseFirestore.instance
                  .collection('attendance')
                  .where('workerId', isEqualTo: workerId)
                  .get(),
              // 3. Fetch Worker Balance
              FirebaseFirestore.instance
                  .collection('workers')
                  .doc(workerId)
                  .get(),
            ]).then((results) {
              double debt = results[0] as double;

              final attendanceDocs = (results[1] as QuerySnapshot).docs;

              // NEW logic: Get Balance safely
              final workerDoc = results[2] as DocumentSnapshot;
              double fetchedBalance = 0;
              if (workerDoc.exists && workerDoc.data() != null) {
                final wData = workerDoc.data() as Map<String, dynamic>;
                fetchedBalance = (wData['balance'] as num?)?.toDouble() ?? 0.0;
              }

              double todaySal = 0;
              final now = DateTime.now();
              for (var doc in attendanceDocs) {
                final data = doc.data() as Map<String, dynamic>;
                final date = (data['date'] as Timestamp).toDate();
                if (date.year == now.year &&
                    date.month == now.month &&
                    date.day == now.day) {
                  if (data['salary'] != null)
                    todaySal += (data['salary'] as num).toDouble();
                }
              }

              if (context.mounted) {
                setState(() {
                  currentDebt = debt;
                  if (currentDebt! < 0) currentDebt = 0;
                  foundedDailySalary = todaySal;
                  currentBalance = fetchedBalance;
                  isLoading = false;

                  // Smart default
                  // If balance is <= 0, force CASH method
                  if (currentBalance! <= 0) {
                    method = 'cash';
                    salaryOption = 'partial'; // Irrelevant but safe default
                  } else if (foundedDailySalary! > 0 && currentDebt! > 0) {
                    salaryOption = 'smart_auto';
                  } else {
                    salaryOption = 'partial';
                    if (foundedDailySalary! == 0)
                      statusMessage = AppLocalizations.of(
                        context,
                      )!.salaryNotFoundToday;
                    else if (currentDebt! == 0)
                      statusMessage = AppLocalizations.of(
                        context,
                      )!.noDebtForWorker;
                  }
                });
              }
            });
          }

          final bool showAmountInput =
              method == 'cash' ||
              (method == 'salary' && salaryOption == 'partial');

          bool canCoverFullDebt = false;
          if (foundedDailySalary != null && currentDebt != null) {
            canCoverFullDebt = foundedDailySalary! >= currentDebt!;
          }

          return AlertDialog(
            title: Text(
              AppLocalizations.of(context)!.repaymentForWorker(workerName),
            ),
            content: isLoading
                ? const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (currentDebt != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "${AppLocalizations.of(context)!.debtSuffix}: ${CurrencyFormatter.format(currentDebt!)} ₸",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        Text(
                          AppLocalizations.of(context)!.repaymentMethod,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: Text(
                                  AppLocalizations.of(context)!.fromSalary,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                subtitle:
                                    (currentBalance != null &&
                                        currentBalance! <= 0)
                                    ? const Text(
                                        "Недостаточно средств (0 ₸)",
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                        ),
                                      )
                                    : null,
                                value: 'salary',
                                groupValue: method,
                                contentPadding: EdgeInsets.zero,
                                activeColor: Colors.red,
                                onChanged:
                                    (currentBalance != null &&
                                        currentBalance! > 0)
                                    ? (val) => setState(() => method = val!)
                                    : null, // Disable if 0 balance
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: Text(
                                  AppLocalizations.of(context)!.inCash,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                value: 'cash',
                                groupValue: method,
                                contentPadding: EdgeInsets.zero,
                                activeColor: Colors.green,
                                onChanged: (val) =>
                                    setState(() => method = val!),
                              ),
                            ),
                          ],
                        ),

                        if (method == 'salary') ...[
                          const Divider(),
                          if (statusMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                statusMessage!,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),

                          if (foundedDailySalary != null &&
                              foundedDailySalary! > 0 &&
                              currentDebt != null &&
                              currentDebt! > 0)
                            RadioListTile<String>(
                              title: Text(
                                canCoverFullDebt
                                    ? AppLocalizations.of(
                                        context,
                                      )!.repayFullDebt
                                    : AppLocalizations.of(
                                        context,
                                      )!.withholdFullSalary,
                              ),
                              subtitle: Text(
                                canCoverFullDebt
                                    ? AppLocalizations.of(
                                        context,
                                      )!.remainingSalary(
                                        CurrencyFormatter.format(currentDebt!),
                                        CurrencyFormatter.format(
                                          foundedDailySalary! - currentDebt!,
                                        ),
                                      )
                                    : AppLocalizations.of(
                                        context,
                                      )!.remainingDebt(
                                        CurrencyFormatter.format(
                                          foundedDailySalary!,
                                        ),
                                        CurrencyFormatter.format(
                                          currentDebt! - foundedDailySalary!,
                                        ),
                                      ),
                                style: TextStyle(
                                  color: canCoverFullDebt
                                      ? Colors.green
                                      : Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              value: 'smart_auto',
                              groupValue: salaryOption,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) =>
                                  setState(() => salaryOption = val!),
                            ),

                          RadioListTile<String>(
                            title: Text(
                              AppLocalizations.of(
                                context,
                              )!.partialOrOtherAmount,
                            ),
                            value: 'partial',
                            groupValue: salaryOption,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) =>
                                setState(() => salaryOption = val!),
                          ),
                        ],

                        const SizedBox(height: 10),

                        if (showAmountInput)
                          TextField(
                            controller: amountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              CurrencyInputFormatter(),
                            ], // Added Formatter
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(
                                context,
                              )!.amountLabelWithCurrency,
                              hintText: AppLocalizations.of(
                                context,
                              )!.amountHintExample,
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.attach_money),
                            ),
                          ),

                        const SizedBox(height: 16),
                        TextField(
                          controller: noteController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            )!.noteLabelOptional,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancelButton),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        setState(() => isLoading = true); // Start Loading
                        double? finalAmount;
                        String finalSalaryOption = salaryOption;

                        if (method == 'salary') {
                          if (salaryOption == 'smart_auto') {
                            if (canCoverFullDebt) {
                              finalAmount = currentDebt;
                              finalSalaryOption = 'debt_cover';
                            } else {
                              finalAmount = foundedDailySalary;
                              finalSalaryOption = 'full_salary';
                            }
                          } else {
                            // Clean spaces
                            final clean = amountController.text.replaceAll(
                              RegExp(r'\s+'),
                              '',
                            );
                            finalAmount = double.tryParse(clean);
                          }
                        } else {
                          // Clean spaces
                          final clean = amountController.text.replaceAll(
                            RegExp(r'\s+'),
                            '',
                          );
                          finalAmount = double.tryParse(clean);
                        }

                        if (finalAmount == null || finalAmount <= 0) {
                          setState(() => isLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(context)!.enterValidAmount,
                              ),
                            ),
                          );
                          return;
                        }

                        String finalNote = "";
                        if (method == 'salary') {
                          if (finalSalaryOption == 'debt_cover')
                            finalNote = AppLocalizations.of(
                              context,
                            )!.fullDebtRepaymentFromSalary;
                          else if (finalSalaryOption == 'full_salary')
                            finalNote = AppLocalizations.of(
                              context,
                            )!.fullSalaryWithholding;
                          else
                            finalNote = AppLocalizations.of(
                              context,
                            )!.partOfSalary;
                        } else {
                          finalNote = AppLocalizations.of(
                            context,
                          )!.cashRepayment;
                        }

                        if (noteController.text.trim().isNotEmpty) {
                          finalNote += ": ${noteController.text.trim()}";
                        }

                        try {
                          await FirebaseFirestore.instance
                              .collection('advance_repayments')
                              .add({
                                'workerId': workerId,
                                'workerName': workerName,
                                'amount': finalAmount,
                                'date': Timestamp.now(),
                                'method': method,
                                'salaryOption': finalSalaryOption,
                                'note': finalNote,
                              });

                          // If repaid from SALARY, we decrease the Worker Balance
                          // (This means the worker uses their pending salary to pay off the debt)
                          if (method == 'salary') {
                            await FirebaseFirestore.instance
                                .collection('workers')
                                .doc(workerId)
                                .update({
                                  'balance': FieldValue.increment(-finalAmount),
                                });
                          }

                          // Send Notification
                          await NotificationService().sendNotification(
                            receiverId: workerId,
                            title: AppLocalizations.of(
                              context,
                            )!.repaymentDialogTitle,
                            body: AppLocalizations.of(context)!
                                .debtReducedNotificationBody(
                                  CurrencyFormatter.format(finalAmount),
                                  finalNote,
                                ),
                            type: 'repayment',
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(context)!.repaidAmount(
                                    CurrencyFormatter.format(finalAmount),
                                  ),
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            setState(() => isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.errorOccurred(e.toString()),
                                ),
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(AppLocalizations.of(context)!.repayButton),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- LOGIC: Show History ---
  void _showWorkerHistory(
    BuildContext context,
    String workerName,
    String workerId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('advance_requests')
              .where('workerId', isEqualTo: workerId)
              .snapshots(),
          builder: (context, advancesSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('advance_repayments')
                  .where('workerId', isEqualTo: workerId)
                  .snapshots(),
              builder: (context, repaymentsSnapshot) {
                if (advancesSnapshot.connectionState ==
                        ConnectionState.waiting ||
                    repaymentsSnapshot.connectionState ==
                        ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final advances = advancesSnapshot.data?.docs ?? [];
                final repayments = repaymentsSnapshot.data?.docs ?? [];

                double totalTaken = 0;
                for (var doc in advances) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data['status'] == 'accepted' ||
                      data['status'] == 'pending') {
                    totalTaken += (data['amount'] as num).toDouble();
                  }
                }

                double totalRepaid = 0;
                for (var doc in repayments) {
                  final data = doc.data() as Map<String, dynamic>;
                  totalRepaid += (data['amount'] as num).toDouble();
                }

                double currentDebt = totalTaken - totalRepaid;

                final List<Map<String, dynamic>> history = [];
                for (var doc in advances) {
                  final data = doc.data() as Map<String, dynamic>;
                  history.add({
                    'type': 'advance',
                    'amount': (data['amount'] as num).toDouble(),
                    'date': (data['requestDate'] as Timestamp).toDate(),
                    'status': data['status'],
                    'note': data['note'],
                  });
                }
                for (var doc in repayments) {
                  final data = doc.data() as Map<String, dynamic>;
                  history.add({
                    'type': 'repayment',
                    'amount': (data['amount'] as num).toDouble(),
                    'date': (data['date'] as Timestamp).toDate(),
                    'status': 'completed',
                    'note': data['note'],
                  });
                }
                history.sort(
                  (a, b) =>
                      (b['date'] as DateTime).compareTo(a['date'] as DateTime),
                );

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    workerName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currentDebt > 0
                                        ? "${AppLocalizations.of(context)!.debtSuffix}: ${CurrencyFormatter.format(currentDebt)} ₸"
                                        : AppLocalizations.of(
                                            context,
                                          )!.nothingOwed,
                                    style: TextStyle(
                                      color: currentDebt > 0
                                          ? Colors.red
                                          : Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              if (currentDebt > 0)
                                ElevatedButton(
                                  onPressed: () => _showRepaymentDialog(
                                    workerId,
                                    workerName,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.repaymentAction,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  AppLocalizations.of(context)!.takenAmount,
                                  totalTaken,
                                  Colors.orange,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 30,
                                color: Colors.grey[300],
                              ),
                              Expanded(
                                child: _buildStatItem(
                                  AppLocalizations.of(
                                    context,
                                  )!.repaidAmountLabel,
                                  totalRepaid,
                                  Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: history.length,
                        separatorBuilder: (c, i) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = history[index];
                          final isRepayment = item['type'] == 'repayment';
                          final date = item['date'] as DateTime;
                          final amount = item['amount'] as double;
                          final status = item['status'];

                          Color amountColor;
                          String prefix;
                          IconData icon;

                          if (isRepayment) {
                            amountColor = Colors.green;
                            prefix = "-";
                            icon = Icons.file_download;
                          } else {
                            if (status == 'accepted' || status == 'completed') {
                              amountColor = Colors.black;
                              prefix = "+";
                              icon = Icons.file_upload;
                            } else if (status == 'rejected') {
                              amountColor = Colors.grey;
                              prefix = "";
                              icon = Icons.cancel;
                            } else {
                              amountColor = Colors.orange;
                              prefix = "+";
                              icon = Icons.pending;
                            }
                          }

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isRepayment
                                  ? Colors.green[50]
                                  : Colors.orange[50],
                              child: Icon(
                                icon,
                                color: isRepayment
                                    ? Colors.green
                                    : Colors.orange,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              isRepayment
                                  ? AppLocalizations.of(context)!.repayment
                                  : AppLocalizations.of(context)!.advance,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              "${DateFormat('dd MMM HH:mm', 'ru').format(date)}\n${item['note'] ?? ''}",
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "$prefix${amount.toInt()} ₸",
                                  style: TextStyle(
                                    color: amountColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (status != 'completed' &&
                                    status != 'accepted')
                                  Text(
                                    status == 'pending'
                                        ? AppLocalizations.of(
                                            context,
                                          )!.pendingStatus
                                        : (status == 'rejected'
                                              ? AppLocalizations.of(
                                                  context,
                                                )!.rejectedStatus
                                              : ''),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: status == 'pending'
                                          ? Colors.orange
                                          : Colors.red,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          "${CurrencyFormatter.format(amount)} ₸",
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(AppLocalizations.of(context)!.advanceTitle),
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
            icon: const Icon(Icons.calendar_month, color: Colors.pink),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.advanceTabActive),
            Tab(text: AppLocalizations.of(context)!.advanceTabHistory),
            Tab(text: AppLocalizations.of(context)!.advanceTabGive),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('advance_requests')
            .snapshots(),
        builder: (context, advancesSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('advance_repayments')
                .snapshots(),
            builder: (context, repaymentsSnapshot) {
              if (advancesSnapshot.connectionState == ConnectionState.waiting ||
                  repaymentsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // 1. Process Data Grouped by Worker
              final Map<String, _WorkerDebtData> workerData = {};

              // Process Advances
              for (var doc in advancesSnapshot.data?.docs ?? []) {
                final data = doc.data() as Map<String, dynamic>;
                final workerId = data['workerId'] as String;
                final workerName = data['workerName'] as String;
                final amount = (data['amount'] as num).toDouble();
                final status = data['status'];

                workerData.putIfAbsent(
                  workerId,
                  () => _WorkerDebtData(id: workerId, name: workerName),
                );

                if (status == 'accepted' || status == 'pending') {
                  workerData[workerId]!.totalTaken += amount;
                }
                if (status == 'pending') {
                  workerData[workerId]!.pendingCount++;
                }
              }

              // Process Repayments
              for (var doc in repaymentsSnapshot.data?.docs ?? []) {
                final data = doc.data() as Map<String, dynamic>;
                final workerId = data['workerId'] as String;
                final workerName = data['workerName'] as String;
                final amount = (data['amount'] as num).toDouble();

                workerData.putIfAbsent(
                  workerId,
                  () => _WorkerDebtData(id: workerId, name: workerName),
                );

                workerData[workerId]!.totalRepaid += amount;
              }

              final activeDebtors = <_WorkerDebtData>[];
              final historyItems = <Map<String, dynamic>>[];

              // 1. Calculate Global Debts
              workerData.forEach((key, data) {
                if (data.currentDebt > 0 || data.pendingCount > 0) {
                  activeDebtors.add(data);
                }
              });

              // 2. Gather Daily History
              // Filter logic for selected date
              final startOfDay = Timestamp.fromDate(
                DateTime(
                  _selectedDate.year,
                  _selectedDate.month,
                  _selectedDate.day,
                ),
              );
              final endOfDay = Timestamp.fromDate(
                DateTime(
                  _selectedDate.year,
                  _selectedDate.month,
                  _selectedDate.day,
                ).add(const Duration(days: 1)),
              );

              for (var doc in advancesSnapshot.data?.docs ?? []) {
                final data = doc.data() as Map<String, dynamic>;
                final date = data['requestDate'] as Timestamp;
                if (date.compareTo(startOfDay) >= 0 &&
                    date.compareTo(endOfDay) < 0) {
                  historyItems.add({'type': 'advance', 'data': data});
                }
              }
              for (var doc in repaymentsSnapshot.data?.docs ?? []) {
                final data = doc.data() as Map<String, dynamic>;
                final date = data['date'] as Timestamp;
                if (date.compareTo(startOfDay) >= 0 &&
                    date.compareTo(endOfDay) < 0) {
                  historyItems.add({'type': 'repayment', 'data': data});
                }
              }

              // Sort history by date descending
              historyItems.sort((a, b) {
                final dateA =
                    (a['data']['date'] ?? a['data']['requestDate'])
                        as Timestamp;
                final dateB =
                    (b['data']['date'] ?? b['data']['requestDate'])
                        as Timestamp;
                return dateB.compareTo(dateA);
              });

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildActiveDebtsList(activeDebtors),
                  _buildHistoryList(historyItems),
                  _buildGiveTab(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildActiveDebtsList(List<_WorkerDebtData> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 60,
              color: Colors.green[300],
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noActiveDebts,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final data = list[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            onTap: () => _showWorkerHistory(context, data.name, data.id),
            leading: CircleAvatar(
              backgroundColor: Colors.orange.withOpacity(0.1),
              child: Text(
                data.name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              data.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: data.pendingCount > 0
                ? Text(
                    AppLocalizations.of(
                      context,
                    )!.pendingLabel(data.pendingCount),
                    style: const TextStyle(color: Colors.orange),
                  )
                : Text(AppLocalizations.of(context)!.activeDebt),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${CurrencyFormatter.format(data.currentDebt)} ₸",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.debtSuffix,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.historyEmptyToday,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isRepayment = item['type'] == 'repayment';
        final data = item['data'] as Map<String, dynamic>;
        final amount = (data['amount'] as num).toDouble();
        final name = isRepayment
            ? data['workerName']
            : data['workerName']; // consistent
        final date =
            (isRepayment ? data['date'] : data['requestDate']) as Timestamp;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isRepayment
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              child: Icon(
                isRepayment ? Icons.arrow_downward : Icons.arrow_upward,
                color: isRepayment ? Colors.green : Colors.orange,
              ),
            ),
            title: Text(name),
            subtitle: Text(DateFormat('HH:mm').format(date.toDate())),
            trailing: Text(
              "${isRepayment ? '-' : '+'}${CurrencyFormatter.format(amount)} ₸",
              style: TextStyle(
                color: isRepayment ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGiveTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('workers').snapshots(),
      builder: (context, workersSnapshot) {
        if (workersSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!workersSnapshot.hasData || workersSnapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Нет работников"));
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('attendance')
              .where(
                'date',
                isEqualTo: Timestamp.fromDate(
                  DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                  ),
                ),
              )
              .snapshots(),
          builder: (context, attendanceSnapshot) {
            if (attendanceSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final presentWorkerIds = <String>{};
            if (attendanceSnapshot.hasData) {
              for (var doc in attendanceSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                presentWorkerIds.add(data['workerId'] as String);
              }
            }

            final allWorkers = workersSnapshot.data!.docs
                .map(
                  (doc) => Worker.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  ),
                )
                .toList();

            final onShift = <Worker>[];
            final offShift = <Worker>[];

            for (var w in allWorkers) {
              if (presentWorkerIds.contains(w.id)) {
                onShift.add(w);
              } else {
                offShift.add(w);
              }
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (onShift.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0, left: 4),
                      child: Row(
                        children: [
                          Icon(Icons.circle, color: Colors.green, size: 12),
                          SizedBox(width: 8),
                          Text(
                            "На смене:", // Removed 'Today'
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...onShift.map((w) => _buildWorkerCard(w, true)),
                    const SizedBox(height: 24),
                  ],

                  if (offShift.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0, left: 4),
                      child: Text(
                        "Не на смене",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    ...offShift.map((w) => _buildWorkerCard(w, false)),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWorkerCard(Worker worker, bool isOnShift) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: isOnShift ? 2 : 1,
      color: isOnShift
          ? theme.cardTheme.color
          : theme.cardTheme.color?.withOpacity(0.7),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                worker.name[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isOnShift)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          worker.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isOnShift
                ? theme.textTheme.bodyLarge?.color
                : theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        ),
        subtitle: Text(worker.position),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // IconButton(
            //   onPressed: () => _showSalaryPaymentDialog(worker),
            //   icon: const Icon(Icons.payments, color: Colors.green),
            //   tooltip: "Выплатить ЗП",
            // ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _showAdvanceDialog(worker),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text("Аванс"),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkerDebtData {
  final String id;
  final String name;
  double totalTaken = 0;
  double totalRepaid = 0;
  int pendingCount = 0;

  _WorkerDebtData({required this.id, required this.name});

  double get currentDebt => totalTaken - totalRepaid;
}
