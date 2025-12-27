import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:ailin_tattileri_app/core/theme/app_colors.dart';
import 'package:ailin_tattileri_app/core/services/notification_service.dart';
import 'package:ailin_tattileri_app/l10n/app_localizations.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
    autoStart: false,
  );
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Allow navigation animation to finish before starting camera
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _controller.start();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!_controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      _controller.start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _processQRCode(String qrData) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    // Stop scanner immediately to prevent double detection
    await _controller.stop();

    final l10n = AppLocalizations.of(context)!;

    try {
      // Check if it's the kitchen QR code
      if (qrData != 'KITCHEN_CHECKIN') {
        throw Exception(l10n.invalidQrCode);
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception(l10n.loginRequired);
      }

      // Find worker by userId
      final workerQuery = await FirebaseFirestore.instance
          .collection('workers')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (workerQuery.docs.isEmpty) {
        throw Exception(l10n.notRegisteredAsWorker);
      }

      final workerDoc = workerQuery.docs.first;
      final workerId = workerDoc.id;
      final workerData = workerDoc.data();

      final today = DateTime.now();
      final dateKey = DateFormat('yyyy-MM-dd').format(today);
      final date = DateTime.parse(dateKey);

      // Check existing attendance
      final attendanceQuery = await FirebaseFirestore.instance
          .collection('attendance')
          .where('workerId', isEqualTo: workerId)
          .where('date', isEqualTo: Timestamp.fromDate(date))
          .limit(1)
          .get();

      String successMessage;
      final nowTime = DateFormat('HH:mm').format(DateTime.now());

      if (attendanceQuery.docs.isEmpty) {
        // First scan - check in
        await FirebaseFirestore.instance.collection('attendance').add({
          'workerId': workerId,
          'workerName': workerData['name'],
          'date': Timestamp.fromDate(date),
          'isPresent': true,
          'checkInTime': Timestamp.now(),
        });

        // Notify Admins
        await NotificationService().sendNotification(
          receiverId: 'admin',
          title: l10n.attendanceCheckInTitle,
          body: l10n.beganWork(workerData['name'], nowTime),
          type: 'attendance_checkin',
        );

        successMessage = "${l10n.checkInMarked}\n$nowTime";
      } else {
        // Second scan - check out
        final attendanceDoc = attendanceQuery.docs.first;
        final attendanceData = attendanceDoc.data();

        if (attendanceData['checkOutTime'] != null) {
          throw Exception(l10n.alreadyCheckedOut);
        }

        final checkInTime = (attendanceData['checkInTime'] as Timestamp)
            .toDate();
        final checkOutTime = DateTime.now();
        final duration = checkOutTime.difference(checkInTime);
        final hoursWorked = duration.inMinutes / 60.0;
        final checkOutTimeStr = DateFormat('HH:mm').format(checkOutTime);

        await FirebaseFirestore.instance
            .collection('attendance')
            .doc(attendanceDoc.id)
            .update({
              'checkOutTime': Timestamp.fromDate(checkOutTime),
              'hoursWorked': hoursWorked,
            });

        // Notify Admins
        await NotificationService().sendNotification(
          receiverId: 'admin',
          title: l10n.attendanceCheckOutTitle,
          body: l10n.finishedWork(
            workerData['name'],
            hoursWorked.toStringAsFixed(1),
          ),
          type: 'attendance_checkout',
        );

        successMessage =
            "${l10n.checkOutMarked}\n$checkOutTimeStr\n${l10n.hoursWorkedLabel}: ${hoursWorked.toStringAsFixed(1)}";
      }

      // Close scanner and return success message to dashboard
      if (mounted) {
        setState(() => _isProcessing = false);
        Navigator.of(context).pop(successMessage);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showError(e.toString());

        // Close scanner on error after delay
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceAll('Exception: ', '')),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(l10n.scanQr),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              // Prevent multiple scans
              if (_isProcessing) return;

              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null && !_isProcessing) {
                  _processQRCode(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          // Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l10n.scanQrInstruction,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}
