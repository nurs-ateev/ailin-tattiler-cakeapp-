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
import 'package:ailin_tattileri_app/l10n/app_localizations.dart';
import 'package:flutter/services.dart';

class WorkerDetailsScreen extends StatefulWidget {
  final Worker worker;
  final String dateKey;

  const WorkerDetailsScreen({
    super.key,
    required this.worker,
    required this.dateKey,
  });

  @override
  State<WorkerDetailsScreen> createState() => _WorkerDetailsScreenState();
}

class _WorkerDetailsScreenState extends State<WorkerDetailsScreen> {
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

    // Lock if it's a previous day
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
        // Lock if salary is already saved
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
        title: Text(AppLocalizations.of(context)!.unlock),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)!.enterUnlockCode),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.code,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_open),
              ),
              obscureText: true,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (_codeController.text == "BEKARYS") {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.invalidCode),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.unlockAction),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() => _isUnlocked = true);
    }
  }

  void _showQRCode(BuildContext context) {
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
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              QrImageView(
                data: widget.worker.id,
                version: QrVersions.auto,
                size: 250,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.scanQrCodeHint,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.close),
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
            SnackBar(content: Text(AppLocalizations.of(context)!.checkInFirst)),
          );
          return;
        }

        // Calculate hours worked
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.enterValidAmount)),
      );
      return;
    }

    // Calculate balance adjustment
    double oldSalary = 0;
    if (_attendance != null && _attendance!.salary != null) {
      oldSalary = _attendance!.salary!;
    }
    final balanceAdjustment = salary - oldSalary;

    await _updateAttendance(salary: salary);

    // Update Worker Balance
    if (balanceAdjustment != 0) {
      await _firestore.collection('workers').doc(widget.worker.id).update({
        'balance': FieldValue.increment(balanceAdjustment),
      });
    }

    // Send Notification
    final dateStr = DateFormat(
      'dd.MM.yyyy',
    ).format(DateTime.parse(widget.dateKey));
    final sent = await NotificationService().sendNotification(
      receiverId: widget.worker.id,
      title: AppLocalizations.of(context)!.salaryAccrualTitle,
      body: AppLocalizations.of(
        context,
      )!.salaryAccrualBody(CurrencyFormatter.format(salary), dateStr),
      type: "salary",
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
                ? AppLocalizations.of(context)!.salarySavedNotificationSent
                : AppLocalizations.of(context)!.salarySavedNotificationFailed,
          ),
          backgroundColor: sent ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
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
      // Update existing
      await _firestore
          .collection('attendance')
          .doc(_attendance!.id)
          .update(attendanceData);
    } else {
      // Create new
      await _firestore.collection('attendance').add(attendanceData);
    }

    await _loadAttendance();
  }

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
    final dateStr = DateFormat(
      'dd MMMM yyyy',
      'ru',
    ).format(DateTime.parse(widget.dateKey));
    final isEditable = !_isLocked || _isUnlocked;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.worker.name, style: theme.textTheme.titleLarge),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showQRCode(context),
            icon: const Icon(Icons.qr_code, color: AppColors.primary),
            tooltip: AppLocalizations.of(context)!.showQrCode,
          ),
          if (_isLocked && !_isUnlocked)
            IconButton(
              onPressed: _showUnlockDialog,
              icon: const Icon(Icons.lock, color: Colors.red),
              tooltip: AppLocalizations.of(context)!.unlock,
            )
          else if (_isUnlocked)
            IconButton(
              onPressed: () {
                setState(() => _isUnlocked = false);
              },
              icon: const Icon(Icons.lock_open, color: Colors.green),
              tooltip: AppLocalizations.of(context)!.lock,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
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
                      child: Row(
                        children: [
                          const Icon(Icons.lock, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.dataLockedHint,
                              style: TextStyle(color: Colors.orange[900]),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Worker Info Card (Redesigned to Horizontal Premium Banner)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: theme.brightness == Brightness.dark
                            ? [
                                AppColors.primary.withOpacity(0.15),
                                theme.cardTheme.color ?? theme.cardColor,
                              ]
                            : [
                                AppColors.primary.withOpacity(0.05),
                                theme.cardTheme.color ?? theme.cardColor,
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
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 16,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.phone_outlined,
                                        size: 14,
                                        color: theme.textTheme.bodySmall?.color
                                            ?.withOpacity(0.5),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        widget.worker.phone,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: theme
                                              .textTheme
                                              .bodySmall
                                              ?.color
                                              ?.withOpacity(0.7),
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
                              _buildHorizontalCredential(
                                icon: Icons.alternate_email,
                                label: "Email",
                                value: widget.worker.invitedEmail!,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 12),
                              _buildHorizontalCredential(
                                icon: Icons.lock_open_outlined,
                                label: "Пароль",
                                value: widget.worker.invitedPassword ?? "---",
                                color: Colors.orange,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Date Header
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Check-in/out Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
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
                          label: AppLocalizations.of(context)!.checkInTime,
                          time: _attendance?.checkInTime,
                          color: Colors.green,
                          isEditable: isEditable,
                          onTap: () => _pickTime(isCheckIn: true),
                        ),
                        const Divider(height: 24),
                        _buildTimeRow(
                          icon: Icons.logout,
                          label: AppLocalizations.of(context)!.checkOutTime,
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

                  // Hours worked (if available)
                  if (_attendance?.hoursWorked != null)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
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
                                Text(
                                  AppLocalizations.of(context)!.hoursWorked,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 14,
                                    color: theme.textTheme.bodyMedium?.color
                                        ?.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${_attendance!.hoursWorked!.toStringAsFixed(1)} ${AppLocalizations.of(context)!.hoursSuffix}",
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
                  StreamBuilder<double>(
                    stream: _getRepaymentStream(),
                    initialData: 0.0,
                    builder: (context, snapshot) {
                      final repaid = snapshot.data ?? 0.0;

                      return ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _salaryController,
                        builder: (context, value, child) {
                          final salaryText = value.text.replaceAll(
                            RegExp(r'\s+'),
                            '',
                          );
                          final salary = double.tryParse(salaryText) ?? 0.0;
                          final netPay = salary - repaid;

                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: theme.cardTheme.color,
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
                                    Text(
                                      AppLocalizations.of(context)!.dailySalary,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
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
                                          labelText: AppLocalizations.of(
                                            context,
                                          )!.amountLabel,
                                          border: const OutlineInputBorder(),
                                          prefixIcon: const Icon(
                                            Icons.currency_exchange,
                                          ),
                                          hintText: AppLocalizations.of(
                                            context,
                                          )!.enterAmount,
                                          filled: true,
                                          fillColor: isEditable
                                              ? (theme.brightness ==
                                                        Brightness.dark
                                                    ? theme
                                                          .colorScheme
                                                          .surfaceContainerHighest
                                                    : Colors.grey[50])
                                              : theme.disabledColor.withOpacity(
                                                  0.1,
                                                ),
                                        ),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        inputFormatters: [
                                          CurrencyInputFormatter(),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton(
                                      onPressed: isEditable
                                          ? _saveSalary
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 20,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        AppLocalizations.of(context)!.save,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Financial Breakdown
                                if (repaid > 0 || salary > 0) ...[
                                  const SizedBox(height: 24),
                                  const Divider(),
                                  const SizedBox(height: 12),
                                  if (repaid > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 8.0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.deductionAdvances,
                                            style: TextStyle(
                                              color: Colors.red[400],
                                            ),
                                          ),
                                          Text(
                                            "- ${CurrencyFormatter.format(repaid)} ₸",
                                            style: TextStyle(
                                              color: Colors.red[400],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.toPay,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      Text(
                                        "${CurrencyFormatter.format(netPay)} ₸",
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHorizontalCredential({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: value));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("$label скопирован"),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? Colors.white.withOpacity(0.04)
                : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.textTheme.bodySmall?.color?.withOpacity(
                          0.5,
                        ),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: label == "Пароль"
                            ? (theme.brightness == Brightness.dark
                                  ? Colors.orange[300]
                                  : Colors.orange[800])
                            : AppColors.primary,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.copy,
                size: 14,
                color: theme.hintColor.withOpacity(0.5),
              ),
            ],
          ),
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
    final theme = Theme.of(context);
    return InkWell(
      onTap: isEditable ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
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
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time != null
                        ? DateFormat('HH:mm').format(time)
                        : AppLocalizations.of(context)!.notMarked,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isEditable
                          ? theme.textTheme.bodyLarge?.color
                          : theme.disabledColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isEditable)
              Icon(Icons.edit, color: color, size: 20)
            else
              Icon(Icons.lock, color: theme.disabledColor, size: 20),
          ],
        ),
      ),
    );
  }
}
