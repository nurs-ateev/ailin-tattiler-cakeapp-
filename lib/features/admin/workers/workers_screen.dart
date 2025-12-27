import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:ailin_tattileri_app/core/models/worker_model.dart';
import 'package:ailin_tattileri_app/core/models/attendance_model.dart';
import 'package:ailin_tattileri_app/core/theme/app_colors.dart';
import 'package:ailin_tattileri_app/features/admin/workers/worker_details_screen.dart';
import 'package:ailin_tattileri_app/features/admin/workers/generate_qr_screen.dart';
import 'package:ailin_tattileri_app/core/utils/input_formatters.dart';
import 'package:ailin_tattileri_app/core/utils/currency_formatter.dart';
import 'package:ailin_tattileri_app/l10n/app_localizations.dart';
import 'package:ailin_tattileri_app/core/services/auth_service.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class WorkersScreen extends StatefulWidget {
  const WorkersScreen({super.key});

  @override
  State<WorkersScreen> createState() => _WorkersScreenState();
}

class _WorkersScreenState extends State<WorkersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Auto-sync silently when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncWorkerTokens();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('dd MMMM yyyy', 'ru').format(_selectedDate);
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.workersTitle,
          style: theme.textTheme.titleLarge,
        ),
        centerTitle: false,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GenerateQRScreen(),
                ),
              );
            },
            icon: const Icon(Icons.qr_code_2, color: AppColors.primary),
            tooltip: AppLocalizations.of(context)!.showQrCode,
          ),
          IconButton(
            onPressed: _showAddWorkerDialog,
            icon: const Icon(Icons.person_add, color: AppColors.primary),
            tooltip: AppLocalizations.of(context)!.addWorker,
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Selector
          Container(
            color: theme.cardTheme.color,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.subtract(
                        const Duration(days: 1),
                      );
                    });
                  },
                  icon: const Icon(Icons.arrow_back_ios),
                ),
                Text(
                  dateStr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.add(
                        const Duration(days: 1),
                      );
                    });
                  },
                  icon: const Icon(Icons.arrow_forward_ios),
                ),
              ],
            ),
          ),

          // Workers List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('workers')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Ошибка: ${snapshot.error}"));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final workers =
                    snapshot.data?.docs
                        .map((doc) {
                          return Worker.fromMap(
                            doc.data() as Map<String, dynamic>,
                            doc.id,
                          );
                        })
                        .where((worker) {
                          final now = DateTime.now();
                          final realToday = DateTime(
                            now.year,
                            now.month,
                            now.day,
                          );
                          final selectedDate = DateTime(
                            _selectedDate.year,
                            _selectedDate.month,
                            _selectedDate.day,
                          );

                          // Hide all workers for future dates
                          if (selectedDate.isAfter(realToday)) return false;

                          // Filter: worker should only appear on or after their creation date
                          final workerDate = DateTime(
                            worker.createdAt.year,
                            worker.createdAt.month,
                            worker.createdAt.day,
                          );
                          return workerDate.isBefore(selectedDate) ||
                              workerDate.isAtSameMomentAs(selectedDate);
                        })
                        .toList() ??
                    [];

                if (workers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: theme.disabledColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.noWorkersForDate,
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _showAddWorkerDialog,
                          icon: const Icon(Icons.add),
                          label: Text(AppLocalizations.of(context)!.addWorker),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: workers.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final worker = workers[index];
                    return _WorkerCard(
                      key: ValueKey('${worker.id}_$dateKey'),
                      worker: worker,
                      dateKey: dateKey,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WorkerDetailsScreen(
                              worker: worker,
                              dateKey: dateKey,
                            ),
                          ),
                        );
                      },
                      onDelete: () => _deleteWorker(worker),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteWorker(Worker worker) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Удалить работника?"),
        content: Text(
          "Вы уверены, что хотите удалить '${worker.name}'? Это действие нельзя отменить.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Отмена"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Удалить"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('workers').doc(worker.id).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Работник успешно удален")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Ошибка: $e")));
        }
      }
    }
  }

  Future<void> _syncWorkerTokens() async {
    int linkedCount = 0;
    int tokenCount = 0;

    // Silent sync (no loading/success snackbars to user)
    try {
      // 1. LINKING PHASE (Match Users to Workers by Phone)
      final usersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'worker')
          .get();

      final workersSnapshot = await _firestore.collection('workers').get();

      // Helper to clean phone
      String cleanPhone(String? phone) {
        if (phone == null) return '';
        return phone.replaceAll(RegExp(r'\D'), ''); // Remove non-digits
      }

      bool phonesMatch(String p1, String p2) {
        if (p1.isEmpty || p2.isEmpty) return false;
        if (p1 == p2) return true;

        // Compare last 10 digits (to handle +7 vs 8)
        if (p1.length >= 10 && p2.length >= 10) {
          final s1 = p1.substring(p1.length - 10);
          final s2 = p2.substring(p2.length - 10);
          return s1 == s2;
        }
        return false;
      }

      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final userPhone = cleanPhone(userData['phone']);
        final userId = userDoc.id;

        if (userPhone.isEmpty) continue;

        // Find matching worker with empty userId or matching userId
        for (var workerDoc in workersSnapshot.docs) {
          final workerData = workerDoc.data();
          final workerPhone = cleanPhone(workerData['phone']);
          final currentWorkerUserId = workerData['userId'];

          // If phones match AND (worker has no user link OR link is correct)
          if (phonesMatch(workerPhone, userPhone)) {
            if (currentWorkerUserId == null || currentWorkerUserId == '') {
              // LINK THEM!
              await workerDoc.reference.update({'userId': userId});
              linkedCount++;
            }
          }
        }
      }

      // 2. TOKEN SYNC PHASE (Copy Tokens from User to Worker profile)
      // Refetch workers to get updated userIds
      final updatedWorkersSnapshot = await _firestore
          .collection('workers')
          .get();

      for (var workerDoc in updatedWorkersSnapshot.docs) {
        final data = workerDoc.data();
        final userId = data['userId'];

        if (userId != null && userId is String && userId.isNotEmpty) {
          final userDoc = await _firestore
              .collection('users')
              .doc(userId)
              .get();
          if (userDoc.exists) {
            final fcmToken = userDoc.data()?['fcmToken'];
            if (fcmToken != null) {
              await workerDoc.reference.update({'fcmToken': fcmToken});
              tokenCount++;
            }
          }
        }
      }

      if (mounted) {
        debugPrint("Silent Sync: Linked $linkedCount, Tokens $tokenCount");
      }
    } catch (e) {
      if (mounted) {
        // Only show error if strictly necessary, or just log
        debugPrint("Silent Sync Error: $e");
      }
    }
  }

  Future<void> _showDebugInfo(Worker worker) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      String debugText = "Worker ID: ${worker.id}\n";
      debugText += "Name: ${worker.name}\n";
      debugText += "Phone (DB): ${worker.phone}\n";
      debugText += "Worker UserID Link: '${worker.userId}'\n";
      debugText +=
          "Worker FCM Token: ${worker.fcmToken != null ? 'YES' : 'NO'}\n\n";

      if (worker.userId == null || worker.userId!.isEmpty) {
        debugText += "❌ NOT LINKED to User.\n";
        // Try to find user by phone (last 10 digits)
        final cleanWorkerPhone = worker.phone.replaceAll(RegExp(r'\D'), '');
        final last10 = cleanWorkerPhone.length >= 10
            ? cleanWorkerPhone.substring(cleanWorkerPhone.length - 10)
            : cleanWorkerPhone;

        debugText += "Looking for user with phone ending in: $last10\n";

        final users = await _firestore.collection('users').get();
        bool foundMatch = false;

        for (var u in users.docs) {
          final uPhone =
              (u.data()['phone'] as String?)?.replaceAll(RegExp(r'\D'), '') ??
              '';
          if (uPhone.endsWith(last10)) {
            foundMatch = true;
            debugText += "✅ FOUND MATCHING USER!\n";
            debugText += "User ID: ${u.id}\n";
            debugText += "User Phone: ${u.data()['phone']}\n";
            debugText +=
                "User FCM Token: ${u.data()['fcmToken'] != null ? 'YES' : 'NO'}\n";
          }
        }
        if (!foundMatch) debugText += "❌ No user found with this phone.\n";
      } else {
        debugText += "✅ LINKED to User.\n";
        final userDoc = await _firestore
            .collection('users')
            .doc(worker.userId)
            .get();
        if (userDoc.exists) {
          debugText += "User Phone: ${userDoc.data()?['phone']}\n";
          final userToken = userDoc.data()?['fcmToken'];
          debugText +=
              "User FCM Token: ${userToken != null ? 'YES' : 'NO, User has no token'}\n";
          if (userToken != null && worker.fcmToken != userToken) {
            debugText += "⚠️ WARN: Tokens do not match!\n";
          }
        } else {
          debugText += "❌ User document does not exist!\n";
        }
      }

      if (mounted) {
        Navigator.pop(context); // Close loading
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Debug Info"), // English debug info is fine
            content: SingleChildScrollView(child: Text(debugText)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  void _showAddWorkerDialog() {
    final nameController = TextEditingController();
    final positionController = TextEditingController();
    final phoneController = TextEditingController();
    // Unique suffix to prevent duplicate logins
    final randomSuffix = Random().nextInt(9000) + 1000;

    // Helper for simple transliteration (Cyrillic to Latin)
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
      // Remove spaces and special chars
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
            title: Text(AppLocalizations.of(context)!.addWorker),
            content: SingleChildScrollView(
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
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.workerName,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    enabled: !isSaving,
                    controller: positionController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.workerPosition,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.work_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    enabled: !isSaving,
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.workerPhone,
                      hintText: "+7 (777) 000-00-00",
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [PhoneInputFormatter()],
                  ),
                  const SizedBox(height: 12),
                  if (generatedEmail.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Данные для входа работника:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildCredentialRow("Email:", generatedEmail),
                          const SizedBox(height: 4),
                          _buildCredentialRow("Пароль:", generatedPassword),
                          const SizedBox(height: 8),
                          Text(
                            "Скопируйте и передайте их работнику",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
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
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (nameController.text.trim().isEmpty) return;

                        setDialogState(() => isSaving = true);

                        try {
                          // 1. Create account in Firebase Auth directly
                          final authService = AuthService();
                          final workerUid = await authService
                              .createWorkerAccountByAdmin(
                                email: generatedEmail,
                                password: generatedPassword,
                                name: nameController.text.trim(),
                                phone: phoneController.text.trim(),
                              );

                          // 2. Create worker profile in Firestore
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
                              const SnackBar(
                                content: Text(
                                  "Аккаунт работника успешно создан",
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Ошибка: $e"),
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
                    : Text(AppLocalizations.of(context)!.add),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value) {
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
                content: Text("$label скопирован"),
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _WorkerCard extends StatefulWidget {
  final Worker worker;
  final String dateKey;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;

  const _WorkerCard({
    super.key,
    required this.worker,
    required this.dateKey,
    required this.onTap,
    this.onLongPress,
    this.onDelete,
  });

  @override
  State<_WorkerCard> createState() => _WorkerCardState();
}

class _WorkerCardState extends State<_WorkerCard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream for Attendance
  Stream<Attendance?> _getAttendanceStream() {
    final date = DateTime.parse(widget.dateKey);
    return _firestore
        .collection('attendance')
        .where('workerId', isEqualTo: widget.worker.id)
        .where('date', isEqualTo: Timestamp.fromDate(date))
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return Attendance.fromMap(
              snapshot.docs.first.data(),
              snapshot.docs.first.id,
            );
          }
          return null;
        });
  }

  // Stream for Repayments (Client-side filtered for safety)
  Stream<double> _getRepaymentStream() {
    final date = DateTime.parse(widget.dateKey);
    return _firestore
        .collection('advance_repayments')
        .where('workerId', isEqualTo: widget.worker.id)
        .snapshots()
        .map((snapshot) {
          double repaid = 0;
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final rDate = (data['date'] as Timestamp).toDate();
            // Check if same day and method is salary
            if (rDate.year == date.year &&
                rDate.month == date.month &&
                rDate.day == date.day &&
                data['method'] == 'salary') {
              repaid += (data['amount'] as num).toDouble();
            }
          }
          return repaid;
        });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<Attendance?>(
      stream: _getAttendanceStream(),
      builder: (context, attendanceSnapshot) {
        final isLoading =
            attendanceSnapshot.connectionState == ConnectionState.waiting;
        final attendance = attendanceSnapshot.data;

        return StreamBuilder<double>(
          stream: _getRepaymentStream(),
          initialData: 0.0,
          builder: (context, repaymentSnapshot) {
            final repaidFromSalary = repaymentSnapshot.data ?? 0.0;

            // Calculate Pay
            double salary = attendance?.salary ?? 0.0;
            double netPay = salary - repaidFromSalary;

            return GestureDetector(
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color ?? theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
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
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text(
                            widget.worker.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
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
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (isLoading)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else if (attendance?.isPresent == true)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 28,
                          )
                        else if (attendance?.isPresent == false)
                          const Icon(Icons.cancel, color: Colors.red, size: 28)
                        else
                          Icon(
                            Icons.help_outline,
                            color: Colors.grey[400],
                            size: 28,
                          ),
                        if (widget.onDelete != null)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.grey,
                            ),
                            onPressed: widget.onDelete,
                          ),
                      ],
                    ),

                    if (attendance?.checkInTime != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTimeChip(
                            icon: Icons.login,
                            label: AppLocalizations.of(context)!.checkIn,
                            time: attendance!.checkInTime!,
                            color: Colors.green,
                          ),
                          if (attendance.checkOutTime != null)
                            _buildTimeChip(
                              icon: Icons.logout,
                              label: AppLocalizations.of(context)!.checkOut,
                              time: attendance.checkOutTime!,
                              color: Colors.orange,
                            ),

                          // FINAL FINANCIAL CALCULATION
                          if (attendance.salary != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // If repaid something, show calculation details
                                if (repaidFromSalary > 0) ...[
                                  Text(
                                    "${AppLocalizations.of(context)!.salaryShort}: ${CurrencyFormatter.format(salary)}",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    "${AppLocalizations.of(context)!.deductionShort}: -${CurrencyFormatter.format(repaidFromSalary)}",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                ],
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: repaidFromSalary > 0
                                        // Highlight if modified
                                        ? Colors.blue.withOpacity(0.1)
                                        : AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: repaidFromSalary > 0
                                        ? Border.all(
                                            color: Colors.blue.withOpacity(0.3),
                                          )
                                        : null,
                                  ),
                                  child: Text(
                                    "${CurrencyFormatter.format(netPay)} ₸",
                                    style: TextStyle(
                                      color: repaidFromSalary > 0
                                          ? Colors.blue[800]
                                          : AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimeChip({
    required IconData icon,
    required String label,
    required DateTime time,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            DateFormat('HH:mm').format(time),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
