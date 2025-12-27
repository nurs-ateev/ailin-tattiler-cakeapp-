import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:ailin_tattileri_app/core/utils/input_formatters.dart'; // Import formatters
import 'package:ailin_tattileri_app/core/utils/currency_formatter.dart';
import 'package:ailin_tattileri_app/l10n/app_localizations.dart';

class AdminExpensesScreen extends StatefulWidget {
  const AdminExpensesScreen({super.key});

  @override
  State<AdminExpensesScreen> createState() => _AdminExpensesScreenState();
}

class _AdminExpensesScreenState extends State<AdminExpensesScreen> {
  DateTime _selectedDate = DateTime.now();

  final Map<String, IconData> categories = {
    'products': Icons.shopping_basket,
    'transport': Icons.directions_car,
    'equipment': Icons.build,
    'communal': Icons.lightbulb,
    'salary': Icons.payments,
    'other': Icons.miscellaneous_services,
  };

  Map<String, String> _getCategoryNames(BuildContext context) {
    return {
      'products': AppLocalizations.of(context)!.categoryProducts,
      'transport': AppLocalizations.of(context)!.categoryTransport,
      'equipment': AppLocalizations.of(context)!.categoryEquipment,
      'communal': AppLocalizations.of(context)!.categoryCommunal,
      'salary': AppLocalizations.of(context)!.categorySalary,
      'other': AppLocalizations.of(context)!.categoryOther,
    };
  }

  void _showAddExpenseDialog() {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String selectedCategory = 'products';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.addExpense),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      CurrencyInputFormatter(),
                    ], // Added formatter
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.amountLabel,
                      hintText: "Например: 5 000",
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(
                        Icons.money_off,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.categoryLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: _getCategoryNames(context).entries.map((e) {
                      return DropdownMenuItem(
                        value: e.key,
                        child: Row(
                          children: [
                            Icon(
                              categories[e.key],
                              size: 20,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 10),
                            Text(e.value),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => selectedCategory = val!),
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
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Clean spaces
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

                  await FirebaseFirestore.instance.collection('expenses').add({
                    'amount': amount,
                    'category': selectedCategory,
                    'note': noteController.text.trim(),
                    'date': Timestamp.now(),
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.expenseAdded,
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text(AppLocalizations.of(context)!.add),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.expensesTitle),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseDialog,
        backgroundColor: Colors.red,
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('expenses')
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
          if (snapshot.hasError) {
            return Center(child: Text("Ошибка: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.noExpensesToday,
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs.toList();
          // Sort client-side to avoid index requirement
          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aDate = aData['date'] as Timestamp;
            final bDate = bData['date'] as Timestamp;
            return bDate.compareTo(aDate);
          });

          double totalExpenses = 0;
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            totalExpenses += (data['amount'] as num).toDouble();
          }

          return Column(
            children: [
              // Total Summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: theme.cardTheme.color,
                child: Column(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.totalExpenses,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${CurrencyFormatter.format(totalExpenses)} ₸",
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),

              // List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final amount = (data['amount'] as num).toDouble();
                    final date = (data['date'] as Timestamp).toDate();
                    final category = data['category'] as String;
                    final note = data['note'] as String;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              categories[category] ?? Icons.help_outline,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getCategoryNames(
                                        context,
                                      )[data['category']] ??
                                      data['category'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (note.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      note,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat(
                                    'dd MMMM yyyy, HH:mm',
                                    'ru',
                                  ).format(date),
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.totalForDay(CurrencyFormatter.format(amount)),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
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
      ),
    );
  }
}
