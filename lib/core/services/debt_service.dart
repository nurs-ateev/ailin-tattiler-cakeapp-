import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ailin_tattileri_app/core/models/payment_history_model.dart';
import 'package:ailin_tattileri_app/core/services/notification_service.dart';

class DebtService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  /// Update partner's total debt when order is created or payment is made
  Future<void> updatePartnerDebt(String userId, double debtChange) async {
    try {
      // Find partner by userId
      final partnerQuery = await _firestore
          .collection('partners')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (partnerQuery.docs.isEmpty) {
        return; // Not a partner, skip
      }

      final partnerDoc = partnerQuery.docs.first;
      final currentDebt =
          (partnerDoc.data()['totalDebt'] as num?)?.toDouble() ?? 0.0;
      final newDebt = currentDebt + debtChange;

      await _firestore.collection('partners').doc(partnerDoc.id).update({
        'totalDebt': newDebt,
      });
    } catch (e) {
      print('Error updating partner debt: $e');
      rethrow;
    }
  }

  /// Get partner's current debt
  Future<double> getPartnerDebt(String userId) async {
    try {
      final partnerQuery = await _firestore
          .collection('partners')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (partnerQuery.docs.isEmpty) {
        return 0.0;
      }

      final partnerDoc = partnerQuery.docs.first;
      return (partnerDoc.data()['totalDebt'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      print('Error getting partner debt: $e');
      return 0.0;
    }
  }

  /// Record a payment and update debt
  Future<void> recordPayment(String orderId, double paymentAmount) async {
    try {
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();

      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final orderData = orderDoc.data()!;
      final userId = orderData['userId'] as String?;

      if (userId == null) {
        return; // Guest order, no debt tracking
      }

      final currentPaidAmount =
          (orderData['paidAmount'] as num?)?.toDouble() ?? 0.0;
      final currentDebtAmount =
          (orderData['debtAmount'] as num?)?.toDouble() ?? 0.0;

      final newPaidAmount = currentPaidAmount + paymentAmount;
      final newDebtAmount = currentDebtAmount - paymentAmount;

      String newPaymentStatus;
      if (newDebtAmount <= 0) {
        newPaymentStatus = 'paid';
      } else if (newPaidAmount > 0) {
        newPaymentStatus = 'partial';
      } else {
        newPaymentStatus = 'unpaid';
      }

      // Update order
      await _firestore.collection('orders').doc(orderId).update({
        'paidAmount': newPaidAmount,
        'debtAmount': newDebtAmount > 0 ? newDebtAmount : 0,
        'paymentStatus': newPaymentStatus,
      });

      // Update partner's total debt
      await updatePartnerDebt(userId, -paymentAmount);
    } catch (e) {
      print('Error recording payment: $e');
      rethrow;
    }
  }

  /// Partner submits payment request
  Future<void> submitPaymentRequest({
    required String orderId,
    required String partnerId,
    required double amount,
    String? note,
  }) async {
    try {
      final payment = PaymentHistoryModel(
        id: '',
        orderId: orderId,
        partnerId: partnerId,
        amount: amount,
        type: 'partner_request',
        status: 'pending',
        createdAt: DateTime.now(),
        note: note,
      );

      await _firestore.collection('payment_history').add(payment.toMap());

      // Send notification to admin
      await _notificationService.sendNotification(
        receiverId: 'admin',
        title: 'Төлем туралы өтініш',
        body: 'Серіктес $amount ₸ төлегенін растауды сұрайды',
        type: 'payment_request',
        data: {'orderId': orderId, 'amount': amount.toString()},
      );
    } catch (e) {
      print('Error submitting payment request: $e');
      rethrow;
    }
  }

  /// Admin records payment (direct)
  Future<void> recordAdminPayment({
    required String orderId,
    required String partnerId,
    required double amount,
    required String adminId,
    String? note,
  }) async {
    try {
      // Create payment history record
      final payment = PaymentHistoryModel(
        id: '',
        orderId: orderId,
        partnerId: partnerId,
        amount: amount,
        type: 'admin_payment',
        status: 'approved',
        createdAt: DateTime.now(),
        adminId: adminId,
        note: note,
      );

      await _firestore.collection('payment_history').add(payment.toMap());

      // Update order
      await _updateOrderPayment(orderId, amount);

      // Update partner debt
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      final userId = orderDoc.data()?['userId'];
      if (userId != null) {
        await updatePartnerDebt(userId, -amount);
      }
    } catch (e) {
      print('Error recording admin payment: $e');
      rethrow;
    }
  }

  /// Admin approves partner payment request
  Future<void> approvePaymentRequest(String paymentId) async {
    try {
      final paymentDoc = await _firestore
          .collection('payment_history')
          .doc(paymentId)
          .get();

      if (!paymentDoc.exists) {
        throw Exception('Payment request not found');
      }

      final payment = PaymentHistoryModel.fromMap(
        paymentDoc.data()!,
        paymentDoc.id,
      );

      // Update payment status
      await _firestore.collection('payment_history').doc(paymentId).update({
        'status': 'approved',
      });

      // Update order
      await _updateOrderPayment(payment.orderId, payment.amount);

      // Update partner debt
      final orderDoc = await _firestore
          .collection('orders')
          .doc(payment.orderId)
          .get();
      final userId = orderDoc.data()?['userId'];
      if (userId != null) {
        await updatePartnerDebt(userId, -payment.amount);

        // Send notification to partner
        await _notificationService.sendNotification(
          receiverId: userId,
          title: 'Төлем расталды',
          body: '${payment.amount} ₸ төлеміңіз расталды',
          type: 'payment_approved',
        );
      }
    } catch (e) {
      print('Error approving payment request: $e');
      rethrow;
    }
  }

  /// Admin rejects partner payment request
  Future<void> rejectPaymentRequest(String paymentId, String? reason) async {
    try {
      final paymentDoc = await _firestore
          .collection('payment_history')
          .doc(paymentId)
          .get();

      if (!paymentDoc.exists) {
        throw Exception('Payment request not found');
      }

      final payment = PaymentHistoryModel.fromMap(
        paymentDoc.data()!,
        paymentDoc.id,
      );

      await _firestore.collection('payment_history').doc(paymentId).update({
        'status': 'rejected',
        'note': reason,
      });

      // Send notification to partner
      final orderDoc = await _firestore
          .collection('orders')
          .doc(payment.orderId)
          .get();
      final userId = orderDoc.data()?['userId'];
      if (userId != null) {
        await _notificationService.sendNotification(
          receiverId: userId,
          title: 'Төлем қабылданбады',
          body: reason ?? 'Төлем өтінішіңіз қабылданбады',
          type: 'payment_rejected',
        );
      }
    } catch (e) {
      print('Error rejecting payment request: $e');
      rethrow;
    }
  }

  /// Update order payment details
  Future<void> _updateOrderPayment(String orderId, double paymentAmount) async {
    final orderDoc = await _firestore.collection('orders').doc(orderId).get();

    if (!orderDoc.exists) {
      throw Exception('Order not found');
    }

    final orderData = orderDoc.data()!;
    final currentPaidAmount =
        (orderData['paidAmount'] as num?)?.toDouble() ?? 0.0;
    final currentDebtAmount =
        (orderData['debtAmount'] as num?)?.toDouble() ?? 0.0;

    final newPaidAmount = currentPaidAmount + paymentAmount;
    final newDebtAmount = currentDebtAmount - paymentAmount;

    String newPaymentStatus;
    if (newDebtAmount <= 0) {
      newPaymentStatus = 'paid';
    } else if (newPaidAmount > 0) {
      newPaymentStatus = 'partial';
    } else {
      newPaymentStatus = 'unpaid';
    }

    await _firestore.collection('orders').doc(orderId).update({
      'paidAmount': newPaidAmount,
      'debtAmount': newDebtAmount > 0 ? newDebtAmount : 0,
      'paymentStatus': newPaymentStatus,
    });
  }

  /// Get payment history for an order
  Stream<List<PaymentHistoryModel>> getOrderPaymentHistory(String orderId) {
    return _firestore
        .collection('payment_history')
        .where('orderId', isEqualTo: orderId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return PaymentHistoryModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  /// Get pending payment requests for admin
  Stream<List<PaymentHistoryModel>> getPendingPaymentRequests() {
    return _firestore
        .collection('payment_history')
        .where('type', isEqualTo: 'partner_request')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs.map((doc) {
            return PaymentHistoryModel.fromMap(doc.data(), doc.id);
          }).toList();

          // Sort manually by date
          requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return requests;
        });
  }
}
