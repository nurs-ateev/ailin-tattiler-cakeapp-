import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:ailin_tattileri_app/core/utils/currency_formatter.dart';

class WorkerSalaryScreen extends StatelessWidget {
  const WorkerSalaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Войдите в систему")));
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("История зарплат"),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
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
            return const Center(child: Text("Данные о работнике не найдены"));
          }

          final workerId = workerSnapshot.data!.docs.first.id;

          // Fetch Attendance (Salaries)
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('attendance')
                .where('workerId', isEqualTo: workerId)
                .snapshots(),
            builder: (context, attendanceSnapshot) {
              // Fetch Repayments
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('advance_repayments')
                    .where('workerId', isEqualTo: workerId)
                    .snapshots(),
                builder: (context, repaymentSnapshot) {
                  if (attendanceSnapshot.hasError) {
                    return Center(
                      child: Text("Error: ${attendanceSnapshot.error}"),
                    );
                  }

                  if (attendanceSnapshot.connectionState ==
                          ConnectionState.waiting ||
                      repaymentSnapshot.connectionState ==
                          ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!attendanceSnapshot.hasData ||
                      attendanceSnapshot.data!.docs.isEmpty) {
                    return Center(
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
                            "История пуста",
                            style: TextStyle(color: theme.hintColor),
                          ),
                        ],
                      ),
                    );
                  }

                  // 1. Prepare Repayments List (filtered by 'salary' method)
                  final repayments =
                      repaymentSnapshot.data?.docs
                          .map((doc) {
                            return doc.data() as Map<String, dynamic>;
                          })
                          .where((data) => data['method'] == 'salary')
                          .toList() ??
                      [];

                  // 2. Prepare Salaries List
                  final salaries = attendanceSnapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final salary = data['salary'];
                    return salary != null && (salary is num) && salary > 0;
                  }).toList();

                  if (salaries.isEmpty) {
                    return Center(
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
                            "Зарплат пока нет",
                            style: TextStyle(color: theme.hintColor),
                          ),
                        ],
                      ),
                    );
                  }

                  // Sort salaries new -> old
                  salaries.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    final aDate = aData['date'] as Timestamp;
                    final bDate = bData['date'] as Timestamp;
                    return bDate.compareTo(aDate);
                  });

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: salaries.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final data =
                          salaries[index].data() as Map<String, dynamic>;
                      final date = (data['date'] as Timestamp).toDate();
                      final totalSalary = (data['salary'] as num).toDouble();
                      final hours =
                          (data['hoursWorked'] as num?)?.toDouble() ?? 0.0;

                      // Calculate Net Pay
                      double repaidToday = 0;
                      for (var r in repayments) {
                        final rDate = (r['date'] as Timestamp).toDate();
                        if (rDate.year == date.year &&
                            rDate.month == date.month &&
                            rDate.day == date.day) {
                          repaidToday += (r['amount'] as num).toDouble();
                        }
                      }

                      final netPay = totalSalary - repaidToday;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.transparent,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.2 : 0.05,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Date Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('dd MMM yyyy').format(date),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textTheme.titleMedium?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${hours.toStringAsFixed(1)} ч. работы",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.hintColor,
                                    ),
                                  ),
                                  if (repaidToday > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        "Удержано: -${CurrencyFormatter.format(repaidToday)} ₸",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.red,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Amount Info
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "${CurrencyFormatter.format(netPay)} ₸",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: repaidToday > 0
                                        ? Colors.blue
                                        : Colors.green,
                                  ),
                                ),
                                if (repaidToday > 0)
                                  Text(
                                    "из ${CurrencyFormatter.format(totalSalary)}",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: theme.hintColor,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
