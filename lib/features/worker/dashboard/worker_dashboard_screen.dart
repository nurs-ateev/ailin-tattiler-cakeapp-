import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:ailin_tattileri_app/core/models/worker_model.dart';
import 'package:ailin_tattileri_app/core/models/attendance_model.dart';
import 'package:ailin_tattileri_app/core/theme/app_colors.dart';
import 'package:ailin_tattileri_app/features/common/notifications/notification_button.dart';
import 'package:ailin_tattileri_app/core/utils/currency_formatter.dart';
import 'package:ailin_tattileri_app/l10n/app_localizations.dart';

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLinking = false;

  Future<void> _attemptAutoLink(User user) async {
    if (_isLinking) return;
    setState(() => _isLinking = true);

    try {
      // 1. Get user's phone from 'users' collection
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return;

      final phone = userDoc.data()?['phone'] as String?;
      if (phone == null || phone.isEmpty) return;

      // 2. Find worker with this phone but no userId (or wrong userId)
      final workersQuery = await _firestore
          .collection('workers')
          .where('phone', isEqualTo: phone)
          .get();

      if (workersQuery.docs.isNotEmpty) {
        // Link all matches just in case (usually there should be one)
        for (var doc in workersQuery.docs) {
          if (doc.data()['userId'] != user.uid) {
            await doc.reference.update({'userId': user.uid});
            print("Successfully linked worker ${doc.id} to user ${user.uid}");
          }
        }
      }
    } catch (e) {
      print("Error auto-linking worker: $e");
    } finally {
      if (mounted) {
        setState(() => _isLinking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(child: Text(AppLocalizations.of(context)!.loginRequired)),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('workers')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .snapshots(),
      builder: (context, workerSnapshot) {
        if (workerSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!workerSnapshot.hasData || workerSnapshot.data!.docs.isEmpty) {
          // If not found, try to auto-link in background
          _attemptAutoLink(user);

          return Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.workerDashboardTitle),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: theme.disabledColor),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.notRegisteredAsWorker,
                    style: TextStyle(color: theme.hintColor),
                  ),
                ],
              ),
            ),
          );
        }

        final workerDoc = workerSnapshot.data!.docs.first;
        final worker = Worker.fromMap(
          workerDoc.data() as Map<String, dynamic>,
          workerDoc.id,
        );

        final today = DateTime.now();
        final dateKey = DateFormat('yyyy-MM-dd').format(today);
        final date = DateTime.parse(dateKey);

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.workerDashboardTitle),
            backgroundColor: theme.appBarTheme.backgroundColor,
            elevation: 0,
            actions: [
              NotificationButton(userId: worker.id),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => context.push('/worker/qr-scanner'),
                icon: const Icon(
                  Icons.qr_code_scanner,
                  color: AppColors.primary,
                ),
                tooltip: AppLocalizations.of(context)!.scanQr,
              ),
            ],
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('attendance')
                .where('workerId', isEqualTo: worker.id)
                .where('date', isEqualTo: Timestamp.fromDate(date))
                .limit(1)
                .snapshots(),
            builder: (context, attendanceSnapshot) {
              Attendance? attendance;
              if (attendanceSnapshot.hasData &&
                  attendanceSnapshot.data!.docs.isNotEmpty) {
                attendance = Attendance.fromMap(
                  attendanceSnapshot.data!.docs.first.data()
                      as Map<String, dynamic>,
                  attendanceSnapshot.data!.docs.first.id,
                );
              }

              // Also fetch repayments for today
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('advance_repayments')
                    .where('workerId', isEqualTo: worker.id)
                    .snapshots(),
                builder: (context, repaymentSnapshot) {
                  double salary = attendance?.salary ?? 0;
                  double repaidToday = 0;

                  if (repaymentSnapshot.hasData) {
                    for (var doc in repaymentSnapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final rDate = (data['date'] as Timestamp).toDate();
                      if (rDate.year == today.year &&
                          rDate.month == today.month &&
                          rDate.day == today.day &&
                          data['method'] == 'salary') {
                        repaidToday += (data['amount'] as num).toDouble();
                      }
                    }
                  }

                  double netPay = salary - repaidToday;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Worker Info Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.cardTheme.color,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  theme.brightness == Brightness.dark
                                      ? 0.2
                                      : 0.05,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: AppColors.primary.withOpacity(
                                  0.1,
                                ),
                                child: Text(
                                  worker.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      worker.name,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            theme.textTheme.titleLarge?.color,
                                      ),
                                    ),
                                    Text(
                                      worker.position,
                                      style: TextStyle(
                                        color: theme.hintColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Date
                        Text(
                          DateFormat('dd MMMM yyyy').format(today),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Status Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.cardTheme.color,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  theme.brightness == Brightness.dark
                                      ? 0.2
                                      : 0.05,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildTimeRow(
                                context: context,
                                icon: Icons.login,
                                label: AppLocalizations.of(
                                  context,
                                )!.checkInTimeLabel,
                                time: attendance?.checkInTime,
                                color: Colors.green,
                              ),
                              Divider(height: 24, color: theme.dividerColor),
                              _buildTimeRow(
                                context: context,
                                icon: Icons.logout,
                                label: AppLocalizations.of(
                                  context,
                                )!.checkOutTimeLabel,
                                time: attendance?.checkOutTime,
                                color: Colors.orange,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Stats Card (Financials)
                        if (attendance?.hoursWorked != null || salary > 0)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: theme.cardTheme.color,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(
                                    theme.brightness == Brightness.dark
                                        ? 0.2
                                        : 0.05,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                if (attendance?.hoursWorked != null)
                                  _buildStatRow(
                                    context: context,
                                    icon: Icons.access_time,
                                    label: AppLocalizations.of(
                                      context,
                                    )!.hoursWorkedLabel,
                                    value:
                                        "${attendance!.hoursWorked!.toStringAsFixed(1)} ч",
                                    color: Colors.blue,
                                  ),

                                if (salary > 0) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12.0,
                                    ),
                                    child: Divider(color: theme.dividerColor),
                                  ),

                                  // Base Salary
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "${AppLocalizations.of(context)!.earned}:",
                                          style: TextStyle(
                                            color: theme.hintColor,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        "${CurrencyFormatter.format(salary)} ₸",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          decoration: repaidToday > 0
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color:
                                              theme.textTheme.bodyLarge?.color,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Repayment if active
                                  if (repaidToday > 0) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            "${AppLocalizations.of(context)!.advanceRepayment}:",
                                            style: TextStyle(
                                              color: Colors.red[300],
                                            ),
                                          ),
                                        ),
                                        Text(
                                          "-${CurrencyFormatter.format(repaidToday)} ₸",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Net Pay Dividend
                                    Divider(
                                      height: 1,
                                      color: theme.dividerColor,
                                    ),
                                    const SizedBox(height: 12),
                                  ],

                                  // Net Total
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          repaidToday > 0
                                              ? AppLocalizations.of(
                                                  context,
                                                )!.totalToPay
                                              : AppLocalizations.of(
                                                  context,
                                                )!.total,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: theme
                                                .textTheme
                                                .titleMedium
                                                ?.color,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        "${CurrencyFormatter.format(netPay)} ₸",
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),

                        // QR Scanner Button
                        if (attendance?.checkOutTime == null)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final result = await context.push(
                                  '/worker/qr-scanner',
                                );
                                if (result != null && context.mounted) {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => Dialog(
                                      child: Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                              size: 48,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              result.toString(),
                                              textAlign: TextAlign.center,
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!.ok,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.qr_code_scanner),
                              label: Text(
                                attendance?.checkInTime == null
                                    ? AppLocalizations.of(
                                        context,
                                      )!.scanForCheckIn
                                    : AppLocalizations.of(
                                        context,
                                      )!.scanForCheckOut,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: theme.disabledColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.shiftCompleted,
                                    style: TextStyle(
                                      color: theme.disabledColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTimeRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required DateTime? time,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 14, color: theme.hintColor),
              ),
              const SizedBox(height: 4),
              Text(
                time != null
                    ? DateFormat('HH:mm').format(time)
                    : AppLocalizations.of(context)!.notMarked,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 14, color: theme.hintColor),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
