import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:ailin_tattileri_app/core/models/advance_request_model.dart';
import 'package:ailin_tattileri_app/core/utils/currency_formatter.dart';
import 'package:ailin_tattileri_app/core/services/notification_service.dart';
import 'package:ailin_tattileri_app/l10n/app_localizations.dart';

class WorkerAdvanceScreen extends StatefulWidget {
  const WorkerAdvanceScreen({super.key});

  @override
  State<WorkerAdvanceScreen> createState() => _WorkerAdvanceScreenState();
}

class _WorkerAdvanceScreenState extends State<WorkerAdvanceScreen> {
  final Set<String> _processingIds = {};

  Future<void> _respondToAdvance(
    BuildContext context,
    String requestId,
    bool accept,
    String workerName,
    double amount,
    String adminId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _processingIds.add(requestId);
    });

    try {
      await FirebaseFirestore.instance
          .collection('advance_requests')
          .doc(requestId)
          .update({
            'status': accept ? 'accepted' : 'rejected',
            'responseDate': Timestamp.now(),
          });

      // Send Notification to Admin
      await NotificationService().sendNotification(
        receiverId: adminId,
        title: accept ? l10n.advanceAccepted : l10n.advanceRejected,
        body: accept
            ? "$workerName принял аванс: ${CurrencyFormatter.format(amount)} ₸"
            : "$workerName отказался от аванса: ${CurrencyFormatter.format(amount)} ₸",
        type: 'advance_response',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(accept ? l10n.accepted : l10n.rejected)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingIds.remove(requestId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(child: Text(AppLocalizations.of(context)!.loginRequired)),
      );
    }

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.myAdvances),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('workers')
            .where('userId', isEqualTo: user.uid)
            .limit(1)
            .snapshots(),
        builder: (context, workerSnapshot) {
          if (workerSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!workerSnapshot.hasData || workerSnapshot.data!.docs.isEmpty) {
            return Center(child: Text(l10n.noWorkerData));
          }

          final workerId = workerSnapshot.data!.docs.first.id;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('advance_requests')
                .where('workerId', isEqualTo: workerId)
                .snapshots(),
            builder: (context, advanceSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('advance_repayments')
                    .where('workerId', isEqualTo: workerId)
                    .snapshots(),
                builder: (context, repaymentSnapshot) {
                  if (advanceSnapshot.connectionState ==
                          ConnectionState.waiting ||
                      repaymentSnapshot.connectionState ==
                          ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Collect data
                  final List<AdvanceRequest> advances =
                      advanceSnapshot.data?.docs
                          .map(
                            (doc) => AdvanceRequest.fromMap(
                              doc.data() as Map<String, dynamic>,
                              doc.id,
                            ),
                          )
                          .toList() ??
                      [];
                  final repayments = repaymentSnapshot.data?.docs ?? [];

                  double totalTaken = 0;
                  double totalRepaid = 0;

                  final List<AdvanceRequest> pendingAdvances = [];

                  for (var advance in advances) {
                    if (advance.status == 'accepted') {
                      totalTaken += advance.amount;
                    } else if (advance.status == 'pending') {
                      pendingAdvances.add(advance);
                    }
                  }

                  for (var doc in repayments) {
                    final data = doc.data() as Map<String, dynamic>;
                    final amount = (data['amount'] as num).toDouble();
                    totalRepaid += amount;
                  }

                  double currentDebt = totalTaken - totalRepaid;

                  // Sort advances by date descending
                  advances.sort(
                    (a, b) => b.requestDate.compareTo(a.requestDate),
                  );
                  pendingAdvances.sort(
                    (a, b) => b.requestDate.compareTo(a.requestDate),
                  );

                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: currentDebt > 0
                                  ? [
                                      Colors.orange.shade800,
                                      Colors.orange.shade400,
                                    ]
                                  : [
                                      Colors.green.shade700,
                                      Colors.green.shade400,
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (currentDebt > 0
                                            ? Colors.orange
                                            : Colors.green)
                                        .withValues(
                                          alpha:
                                              theme.brightness ==
                                                  Brightness.dark
                                              ? 0.5
                                              : 0.3,
                                        ),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                l10n.currentDebt,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "${currentDebt.toInt()} ₸",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        l10n.takenAmount,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        "${totalTaken.toInt()} ₸",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    width: 1,
                                    height: 20,
                                    color: Colors.white24,
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        l10n.repaidAmountLabel,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        "${totalRepaid.toInt()} ₸",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Repayments
                      if (repayments.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              l10n.repayments,
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              child: _buildRepaymentCard(
                                context,
                                repayments[index],
                              ),
                            ),
                            childCount: repayments.length,
                          ),
                        ),
                      ],

                      // Pending Advances (Objects with Accept/Reject)
                      if (pendingAdvances.isNotEmpty) ...[
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              l10n.pendingAdvances,
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              child: _buildAdvanceCard(
                                context,
                                pendingAdvances[index],
                              ),
                            ),
                            childCount: pendingAdvances.length,
                          ),
                        ),
                      ],

                      // Advance History
                      if (advances.isNotEmpty) ...[
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              l10n.advanceHistory,
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              child: _buildAdvanceCard(
                                context,
                                advances[index],
                              ),
                            ),
                            childCount: advances.length,
                          ),
                        ),
                      ],

                      if (repayments.isEmpty &&
                          pendingAdvances.isEmpty &&
                          advances.isEmpty)
                        SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 64,
                                  color: theme.disabledColor,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.noAdvancesOrRepayments,
                                  style: TextStyle(color: theme.hintColor),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRepaymentCard(
    BuildContext context,
    QueryDocumentSnapshot repaymentDoc,
  ) {
    final theme = Theme.of(context);
    final data = repaymentDoc.data() as Map<String, dynamic>;
    final amount = (data['amount'] as num).toDouble();
    final date = (data['date'] as Timestamp).toDate();
    final note = data['note'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.4 : 0.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.2 : 0.02,
            ),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.payments, color: Colors.green),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.debtRepayment,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMM yyyy').format(date),
                  style: TextStyle(color: theme.hintColor, fontSize: 12),
                ),
                if (note != null && note.isNotEmpty)
                  Text(
                    note,
                    style: TextStyle(color: theme.hintColor, fontSize: 12),
                  ),
              ],
            ),
          ),
          Text(
            "-${CurrencyFormatter.format(amount)} ₸",
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvanceCard(BuildContext context, AdvanceRequest advance) {
    final theme = Theme.of(context);
    final status = advance.status;
    final isProcessing = _processingIds.contains(advance.id);

    Color statusColor = Colors.orange;
    String statusText = AppLocalizations.of(context)!.pending;

    if (status == 'accepted') {
      statusColor = Colors.black; // Standard
      statusText = AppLocalizations.of(context)!.accepted;
    } else if (status == 'rejected') {
      statusColor = Colors.red;
      statusText = AppLocalizations.of(context)!.rejected;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.2 : 0.03,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: theme.brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.advance,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: status == 'rejected'
                            ? theme.disabledColor
                            : theme.textTheme.titleMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM yyyy').format(advance.requestDate),
                      style: TextStyle(color: theme.hintColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "+${(advance.amount).toInt()} ₸",
                    style: TextStyle(
                      color: status == 'rejected'
                          ? theme.disabledColor
                          : theme.textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (status == 'pending')
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: isProcessing
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => _respondToAdvance(
                            context,
                            advance.id,
                            false,
                            advance.workerName,
                            advance.amount,
                            advance.adminId ?? 'admin',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: Text(AppLocalizations.of(context)!.reject),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () => _respondToAdvance(
                            context,
                            advance.id,
                            true,
                            advance.workerName,
                            advance.amount,
                            advance.adminId ?? 'admin',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(AppLocalizations.of(context)!.accept),
                        ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }
}
