import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:ailin_tattileri_app/core/models/worker_model.dart';
import 'package:ailin_tattileri_app/core/models/attendance_model.dart';
import 'package:ailin_tattileri_app/core/theme/app_colors.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ailin_tattileri_app/core/services/notification_service.dart';
import 'package:ailin_tattileri_app/core/utils/currency_formatter.dart';
import 'package:ailin_tattileri_app/core/utils/input_formatters.dart';
import 'package:ailin_tattileri_app/core/services/auth_service.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class DesktopEmployeesScreen extends StatefulWidget {
  const DesktopEmployeesScreen({super.key});

  @override
  State<DesktopEmployeesScreen> createState() => _DesktopEmployeesScreenState();
}

class _DesktopEmployeesScreenState extends State<DesktopEmployeesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Жұмысшылар'),
        actions: [
          IconButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
            icon: const Icon(Icons.calendar_month),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _showAddWorkerDialog,
            icon: const Icon(Icons.add),
            label: const Text('Қосу'),
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Тізім'),
            Tab(text: 'Төлеу керек'),
            Tab(text: 'Күтуде'),
            Tab(text: 'Тарих'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWorkersListTab(dateKey),
          _buildUnpaidTab(),
          _buildPendingTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  // TAB 1: Workers List
  Widget _buildWorkersListTab(String dateKey) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('workers').orderBy('name').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Жұмысшылар жоқ'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _showAddWorkerDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Қосу'),
                ),
              ],
            ),
          );
        }

        final workers = snapshot.data!.docs
            .map(
              (doc) =>
                  Worker.fromMap(doc.data() as Map<String, dynamic>, doc.id),
            )
            .where((worker) {
              final now = DateTime.now();
              final realToday = DateTime(now.year, now.month, now.day);
              final selectedDate = DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
              );

              if (selectedDate.isAfter(realToday)) return false;

              final workerDate = DateTime(
                worker.createdAt.year,
                worker.createdAt.month,
                worker.createdAt.day,
              );
              return workerDate.isBefore(selectedDate) ||
                  workerDate.isAtSameMomentAs(selectedDate);
            })
            .toList();

        if (workers.isEmpty) {
          return const Center(child: Text('Бұл күнге жұмысшылар жоқ'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: workers.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _WorkerCard(
              worker: workers[index],
              dateKey: dateKey,
              onTap: () => _showWorkerDetails(workers[index], dateKey),
            );
          },
        );
      },
    );
  }

  // TAB 2: Unpaid Workers
  Widget _buildUnpaidTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('workers')
          .where('balance', isGreaterThan: 0)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Төлеу керек жұмысшылар жоқ'),
              ],
            ),
          );
        }

        final workers = snapshot.data!.docs
            .map(
              (doc) =>
                  Worker.fromMap(doc.data() as Map<String, dynamic>, doc.id),
            )
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: workers.length,
          itemBuilder: (context, index) {
            return _WorkerPaymentCard(worker: workers[index]);
          },
        );
      },
    );
  }

  // TAB 3: Pending Payments
  Widget _buildPendingTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
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
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_empty, size: 64, color: Colors.orange),
                SizedBox(height: 16),
                Text('Күтуде төлемдер жоқ'),
              ],
            ),
          );
        }

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
            final workerName = data['workerName'] ?? 'Белгісіз';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.hourglass_empty, color: Colors.white),
                ),
                title: Text(
                  workerName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(DateFormat('dd MMMM HH:mm', 'ru').format(date)),
                trailing: Text(
                  '${CurrencyFormatter.format(amount)} ₸',
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

  // TAB 4: Payment History
  Widget _buildHistoryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
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
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.blue),
                SizedBox(height: 16),
                Text('Төлем тарихы жоқ'),
              ],
            ),
          );
        }

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
            final workerName = data['workerName'] ?? 'Белгісіз';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.check, color: Colors.white),
                ),
                title: Text(
                  workerName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Төленді: ${DateFormat('dd MMM HH:mm', 'ru').format(date)}',
                ),
                trailing: Text(
                  '${CurrencyFormatter.format(amount)} ₸',
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

  void _showWorkerDetails(Worker worker, String dateKey) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            _WorkerDetailsDialog(worker: worker, dateKey: dateKey),
      ),
    );
  }

  void _showAddWorkerDialog() {
    final nameController = TextEditingController();
    final positionController = TextEditingController();
    final phoneController = TextEditingController();
    final randomSuffix = Random().nextInt(9000) + 1000;

    String transliterate(String text) {
      const cyrillic = 'абвгдейжзийклмнопрстуфхцчшщыэюя';
      const latin = [
        'a',
        'b',
        'v',
        'g',
        'd',
        'e',
        'y',
        'zh',
        'z',
        'i',
        'y',
        'k',
        'l',
        'm',
        'n',
        'o',
        'p',
        'r',
        's',
        't',
        'u',
        'f',
        'h',
        'ts',
        'ch',
        'sh',
        'shch',
        'y',
        'e',
        'yu',
        'ya',
      ];
      String result = text.toLowerCase();
      for (int i = 0; i < cyrillic.length; i++) {
        result = result.replaceAll(cyrillic[i], latin[i]);
      }
      return result.replaceAll(RegExp(r'[^a-z0-9]'), '');
    }

    String generatedEmail = '';
    String generatedPassword = '123worker';
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Жаңа жұмысшы қосу'),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    enabled: !isSaving,
                    controller: nameController,
                    onChanged: (val) {
                      setDialogState(() {
                        if (val.trim().isNotEmpty) {
                          final transName = transliterate(val.trim());
                          generatedEmail = '$transName$randomSuffix@work.kz';
                          generatedPassword = '${transName}worker$randomSuffix';
                        } else {
                          generatedEmail = '';
                          generatedPassword = '123worker';
                        }
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Аты-жөні',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    enabled: !isSaving,
                    controller: positionController,
                    decoration: const InputDecoration(
                      labelText: 'Лауазымы',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.work_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    enabled: !isSaving,
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Телефон',
                      hintText: '+7 (777) 000-00-00',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [PhoneInputFormatter()],
                  ),
                  if (generatedEmail.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Кіру деректері:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildCredentialRow(
                            'Email:',
                            generatedEmail,
                            context,
                          ),
                          const SizedBox(height: 4),
                          _buildCredentialRow(
                            'Пароль:',
                            generatedPassword,
                            context,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
                child: const Text('Болдырмау'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (nameController.text.trim().isEmpty) return;

                        setDialogState(() => isSaving = true);

                        try {
                          final authService = AuthService();
                          final workerUid = await authService
                              .createWorkerAccountByAdmin(
                                email: generatedEmail,
                                password: generatedPassword,
                                name: nameController.text.trim(),
                                phone: phoneController.text.trim(),
                              );

                          final workerData = {
                            'userId': workerUid,
                            'name': nameController.text.trim(),
                            'position': positionController.text.trim(),
                            'phone': phoneController.text.trim(),
                            'hourlyRate': 0.0,
                            'invitedEmail': generatedEmail.toLowerCase().trim(),
                            'invitedPassword': generatedPassword,
                            'createdAt': Timestamp.fromDate(
                              DateTime(
                                _selectedDate.year,
                                _selectedDate.month,
                                _selectedDate.day,
                                DateTime.now().hour,
                                DateTime.now().minute,
                              ),
                            ),
                            'balance': 0.0,
                          };

                          await _firestore
                              .collection('workers')
                              .add(workerData);

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Жұмысшы қосылды')),
                            );
                          }
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Қате: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Қосу'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value, BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 16),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$label көшірілді'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),
      ],
    );
  }
}

// Worker Card Widget
class _WorkerCard extends StatelessWidget {
  final Worker worker;
  final String dateKey;
  final VoidCallback onTap;

  const _WorkerCard({
    required this.worker,
    required this.dateKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('workerId', isEqualTo: worker.id)
          .where('date', isEqualTo: Timestamp.fromDate(DateTime.parse(dateKey)))
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        final attendance = snapshot.hasData && snapshot.data!.docs.isNotEmpty
            ? Attendance.fromMap(
                snapshot.data!.docs.first.data() as Map<String, dynamic>,
                snapshot.data!.docs.first.id,
              )
            : null;

        return Card(
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      worker.name[0].toUpperCase(),
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
                          worker.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          worker.position,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  if (attendance != null) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${(attendance.hoursWorked ?? 0).toStringAsFixed(1)} сағат',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          '${CurrencyFormatter.format(attendance.salary ?? 0)} ₸',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ] else
                    const Text(
                      'Қатысу жоқ',
                      style: TextStyle(color: Colors.grey),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Worker Payment Card Widget
class _WorkerPaymentCard extends StatelessWidget {
  final Worker worker;

  const _WorkerPaymentCard({required this.worker});

  Stream<double> _getPendingPaymentsStream() {
    return FirebaseFirestore.instance
        .collection('salary_payments')
        .where('workerId', isEqualTo: worker.id)
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
        title: Text('${worker.name} үшін төлем'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ағымдағы қарыз: ${CurrencyFormatter.format(currentDebt)} ₸'),
            if (worker.balance > currentDebt)
              Text(
                'Жалпы база: ${CurrencyFormatter.format(worker.balance)} ₸',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Төлем сомасы',
                suffixText: '₸',
                border: OutlineInputBorder(),
              ),
              inputFormatters: [CurrencyInputFormatter()],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Болдырмау'),
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
            child: const Text('Төлеу', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null && context.mounted) {
      try {
        await FirebaseFirestore.instance.collection('salary_payments').add({
          'workerId': worker.id,
          'workerName': worker.name,
          'amount': result,
          'date': Timestamp.now(),
          'status': 'pending_confirmation',
          'processedBy': 'admin',
        });

        await NotificationService().sendNotification(
          receiverId: worker.id,
          title: 'Төлем жіберілді',
          body:
              '${CurrencyFormatter.format(result)} ₸ төлем жіберілді. Растаңыз.',
          type: 'payment_confirmation',
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${CurrencyFormatter.format(result)} ₸ ${worker.name} үшін жіберілді',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Қате: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: _getPendingPaymentsStream(),
      initialData: 0.0,
      builder: (context, snapshot) {
        final pendingAmount = snapshot.data ?? 0.0;
        final actualDebt = worker.balance - pendingAmount;

        if (actualDebt <= 0) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    worker.name[0],
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        worker.position,
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (pendingAmount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Күтуде: ${CurrencyFormatter.format(pendingAmount)} ₸',
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
                      '${CurrencyFormatter.format(actualDebt)} ₸',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ElevatedButton(
                      onPressed: () => _showPaymentDialog(context, actualDebt),
                      child: const Text('Төлеу'),
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

// Worker Details Dialog (Full Screen)
class _WorkerDetailsDialog extends StatefulWidget {
  final Worker worker;
  final String dateKey;

  const _WorkerDetailsDialog({required this.worker, required this.dateKey});

  @override
  State<_WorkerDetailsDialog> createState() => _WorkerDetailsDialogState();
}

class _WorkerDetailsDialogState extends State<_WorkerDetailsDialog> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  Attendance? _attendance;
  bool _isLoading = true;
  bool _isLocked = false;
  bool _isUnlocked = false;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
    _checkIfLocked();
  }

  @override
  void dispose() {
    _salaryController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _checkIfLocked() {
    final today = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(today);

    if (widget.dateKey != todayKey) {
      setState(() => _isLocked = true);
    }
  }

  Future<void> _loadAttendance() async {
    setState(() => _isLoading = true);

    final date = DateTime.parse(widget.dateKey);
    final snapshot = await _firestore
        .collection('attendance')
        .where('workerId', isEqualTo: widget.worker.id)
        .where('date', isEqualTo: Timestamp.fromDate(date))
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final attendance = Attendance.fromMap(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
      setState(() {
        _attendance = attendance;
        _salaryController.text = attendance.salary != null
            ? CurrencyFormatter.format(attendance.salary!)
            : '';
        if (attendance.salary != null && attendance.salary! > 0) {
          _isLocked = true;
        }
        _isLoading = false;
      });
    } else {
      setState(() {
        _attendance = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _showUnlockDialog() async {
    _codeController.clear();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Құлыпты ашу'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Құлыпты ашу кодын енгізіңіз'),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Код',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_open),
              ),
              obscureText: true,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Болдырмау'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_codeController.text == 'BEKARYS') {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Қате код')));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ашу'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() => _isUnlocked = true);
    }
  }

  void _showQRCode() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.worker.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.worker.position,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              QrImageView(
                data: widget.worker.id,
                version: QrVersions.auto,
                size: 250,
              ),
              const SizedBox(height: 16),
              const Text(
                'QR кодты сканерлеңіз',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Жабу'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickTime({required bool isCheckIn}) async {
    if (_isLocked && !_isUnlocked) {
      await _showUnlockDialog();
      if (!_isUnlocked) return;
    }

    final initialTime = isCheckIn
        ? _attendance?.checkInTime ?? DateTime.now()
        : _attendance?.checkOutTime ?? DateTime.now();

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialTime),
    );

    if (picked != null) {
      final date = DateTime.parse(widget.dateKey);
      final selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        picked.hour,
        picked.minute,
      );

      if (isCheckIn) {
        await _updateAttendance(checkInTime: selectedDateTime);
      } else {
        if (_attendance?.checkInTime == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Алдымен келу уақытын белгілеңіз')),
          );
          return;
        }

        final checkIn = _attendance!.checkInTime!;
        final duration = selectedDateTime.difference(checkIn);
        final hoursWorked = duration.inMinutes / 60.0;

        await _updateAttendance(
          checkOutTime: selectedDateTime,
          hoursWorked: hoursWorked,
        );
      }
    }
  }

  Future<void> _saveSalary() async {
    if (_isLocked && !_isUnlocked) {
      await _showUnlockDialog();
      if (!_isUnlocked) return;
    }

    final cleanSalary = _salaryController.text.replaceAll(RegExp(r'\s+'), '');
    final salary = double.tryParse(cleanSalary);
    if (salary == null || salary <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Дұрыс сома енгізіңіз')));
      return;
    }

    double oldSalary = 0;
    if (_attendance != null && _attendance!.salary != null) {
      oldSalary = _attendance!.salary!;
    }
    final balanceAdjustment = salary - oldSalary;

    await _updateAttendance(salary: salary);

    if (balanceAdjustment != 0) {
      await _firestore.collection('workers').doc(widget.worker.id).update({
        'balance': FieldValue.increment(balanceAdjustment),
      });
    }

    final dateStr = DateFormat(
      'dd.MM.yyyy',
    ).format(DateTime.parse(widget.dateKey));
    final sent = await NotificationService().sendNotification(
      receiverId: widget.worker.id,
      title: 'Жалақы есептелді',
      body: '${CurrencyFormatter.format(salary)} ₸ жалақы есептелді ($dateStr)',
      type: 'salary',
    );

    if (mounted) {
      setState(() {
        _isLocked = true;
        _isUnlocked = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sent
                ? 'Жалақы сақталды және хабарлама жіберілді'
                : 'Жалақы сақталды, бірақ хабарлама жіберілмеді',
          ),
          backgroundColor: sent ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  Future<void> _updateAttendance({
    DateTime? checkInTime,
    DateTime? checkOutTime,
    double? hoursWorked,
    double? salary,
  }) async {
    final date = DateTime.parse(widget.dateKey);
    final attendanceData = {
      'workerId': widget.worker.id,
      'workerName': widget.worker.name,
      'date': Timestamp.fromDate(date),
      'isPresent': true,
      if (checkInTime != null) 'checkInTime': Timestamp.fromDate(checkInTime),
      if (checkOutTime != null)
        'checkOutTime': Timestamp.fromDate(checkOutTime),
      if (hoursWorked != null) 'hoursWorked': hoursWorked,
      if (salary != null) 'salary': salary,
    };

    if (_attendance != null) {
      await _firestore
          .collection('attendance')
          .doc(_attendance!.id)
          .update(attendanceData);
    } else {
      await _firestore.collection('attendance').add(attendanceData);
    }

    await _loadAttendance();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat(
      'dd MMMM yyyy',
      'ru',
    ).format(DateTime.parse(widget.dateKey));
    final isEditable = !_isLocked || _isUnlocked;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.worker.name),
        actions: [
          IconButton(
            onPressed: _showQRCode,
            icon: const Icon(Icons.qr_code),
            tooltip: 'QR код',
          ),
          if (_isLocked && !_isUnlocked)
            IconButton(
              onPressed: _showUnlockDialog,
              icon: const Icon(Icons.lock, color: Colors.red),
              tooltip: 'Құлыпты ашу',
            )
          else if (_isUnlocked)
            IconButton(
              onPressed: () {
                setState(() => _isUnlocked = false);
              },
              icon: const Icon(Icons.lock_open, color: Colors.green),
              tooltip: 'Құлыптау',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lock Warning
                  if (_isLocked && !_isUnlocked)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lock, color: Colors.orange),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Деректер құлыпталған. Өзгерту үшін құлыпты ашыңыз.',
                              style: TextStyle(color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Worker Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.05),
                          theme.cardColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.2),
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 35,
                                backgroundColor: AppColors.primary.withOpacity(
                                  0.1,
                                ),
                                child: Text(
                                  widget.worker.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 28,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.worker.name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.worker.position,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.phone_outlined,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        widget.worker.phone,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (widget.worker.invitedEmail != null) ...[
                          const SizedBox(height: 20),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildCredential(
                                  icon: Icons.alternate_email,
                                  label: 'Email',
                                  value: widget.worker.invitedEmail!,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildCredential(
                                  icon: Icons.lock_open_outlined,
                                  label: 'Пароль',
                                  value: widget.worker.invitedPassword ?? '---',
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Date Header
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Check-in/out Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildTimeRow(
                          icon: Icons.login,
                          label: 'Келу уақыты',
                          time: _attendance?.checkInTime,
                          color: Colors.green,
                          isEditable: isEditable,
                          onTap: () => _pickTime(isCheckIn: true),
                        ),
                        const Divider(height: 24),
                        _buildTimeRow(
                          icon: Icons.logout,
                          label: 'Кету уақыты',
                          time: _attendance?.checkOutTime,
                          color: Colors.orange,
                          isEditable:
                              isEditable && _attendance?.checkInTime != null,
                          onTap: () => _pickTime(isCheckIn: false),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Hours worked
                  if (_attendance?.hoursWorked != null)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.access_time,
                              color: Colors.blue,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Жұмыс сағаты',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_attendance!.hoursWorked!.toStringAsFixed(1)} сағат',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Salary Input Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.attach_money,
                                color: Colors.green,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Күнделікті жалақы',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _salaryController,
                                keyboardType: TextInputType.number,
                                enabled: isEditable,
                                decoration: InputDecoration(
                                  labelText: 'Сома',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(
                                    Icons.currency_exchange,
                                  ),
                                  hintText: 'Соманы енгізіңіз',
                                  filled: true,
                                  fillColor: isEditable
                                      ? Colors.grey[50]
                                      : Colors.grey[200],
                                ),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                inputFormatters: [CurrencyInputFormatter()],
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: isEditable ? _saveSalary : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Сақтау',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTimeRow({
    required IconData icon,
    required String label,
    required DateTime? time,
    required Color color,
    required bool isEditable,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isEditable ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
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
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time != null ? DateFormat('HH:mm').format(time) : '--:--',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (isEditable)
              Icon(Icons.edit, color: color, size: 20)
            else
              const Icon(Icons.lock, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCredential({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.copy, size: 14, color: color),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$label көшірілді'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
