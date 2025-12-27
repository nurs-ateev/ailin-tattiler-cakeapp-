import 'package:ailin_tattileri_app/core/models/order_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ailin_tattileri_app/core/services/notification_service.dart';
import 'package:ailin_tattileri_app/core/services/debt_service.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final DebtService _debtService = DebtService();

  // Generate order number: P-YY-XXXX for partners, K-YY-XXXX for clients
  Future<String> generateOrderNumber(bool isPartner) async {
    final now = DateTime.now();
    final year = now.year.toString().substring(2); // Last 2 digits of year
    final prefix = isPartner ? 'P' : 'K';
    final counterName = isPartner
        ? 'partner_orders_${now.year}'
        : 'client_orders_${now.year}';

    // Use Firestore transaction to increment counter atomically
    final counterRef = _firestore.collection('counters').doc(counterName);

    return await _firestore.runTransaction<String>((transaction) async {
      final counterDoc = await transaction.get(counterRef);

      int newCount = 1;
      if (counterDoc.exists) {
        newCount = ((counterDoc.data()?['count'] ?? 0) as int) + 1;
      }

      transaction.set(counterRef, {'count': newCount}, SetOptions(merge: true));

      // Format: P-25-0001 or K-25-0001
      final orderNumber =
          '$prefix-$year-${newCount.toString().padLeft(4, '0')}';
      return orderNumber;
    });
  }

  Future<String> createOrder(OrderModel order) async {
    // Check if user is a partner
    bool isPartner = false;
    if (order.userId != null) {
      final partnerQuery = await _firestore
          .collection('partners')
          .where('userId', isEqualTo: order.userId)
          .limit(1)
          .get();
      isPartner = partnerQuery.docs.isNotEmpty;
    }

    // Generate order number
    final orderNumber = await generateOrderNumber(isPartner);

    // Create order with order number
    final orderData = order.toMap();
    orderData['orderNumber'] = orderNumber;
    final docRef = await _firestore.collection('orders').add(orderData);

    // DON'T update partner debt immediately if order is pending approval
    // Debt will be added only after admin approves the order
    if (order.userId != null &&
        order.debtAmount > 0 &&
        !order.isPendingApproval) {
      try {
        await _debtService.updatePartnerDebt(order.userId!, order.debtAmount);
      } catch (e) {
        print('⚠️ Не удалось обновить долг партнера: $e');
      }
    }

    // Отправляем уведомление админу о новом заказе
    try {
      String notificationTitle = '✅ Новый заказ!';
      String notificationBody =
          'Заказ $orderNumber на сумму ${order.totalAmount.toStringAsFixed(0)} ₸';

      // If it's a debt order pending approval, notify admin differently
      if (order.isPendingApproval) {
        notificationTitle = '⏳ Запрос на заказ в долг';
        notificationBody =
            'Заказ $orderNumber: партнер запрашивает ${order.debtAmount.toStringAsFixed(0)} ₸ в долг';
      }

      await _notificationService.sendNotification(
        receiverId: 'admin', // Отправить всем админам
        title: notificationTitle,
        body: notificationBody,
        type: order.isPendingApproval ? 'debt_order_approval' : 'new_order',
        data: {
          'amount': order.totalAmount.toStringAsFixed(0),
          'orderId': docRef.id,
          'orderNumber': orderNumber,
        },
      );
    } catch (e) {
      print('⚠️ Не удалось отправить уведомление админу: $e');
    }

    return docRef.id;
  }

  Stream<List<OrderModel>> getOrders() {
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return OrderModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  Stream<List<OrderModel>> getUserOrders(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return OrderModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    // Обновляем статус заказа
    await _firestore.collection('orders').doc(orderId).update({
      'status': newStatus,
    });

    // Получаем информацию о заказе для отправки уведомления
    try {
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (orderDoc.exists) {
        final userId = orderDoc.data()?['userId'];

        if (userId != null) {
          // Формируем текст уведомления в зависимости от статуса
          String statusMessage;
          String emoji;

          switch (newStatus) {
            case 'processing':
              emoji = '⏳';
              statusMessage = 'Ваш заказ принят в обработку';
              break;
            case 'ready':
              emoji = '✅';
              statusMessage = 'Ваш заказ готов к выдаче!';
              break;
            case 'completed':
              emoji = '🎉';
              statusMessage = 'Заказ выполнен! Спасибо за покупку';
              break;
            case 'cancelled':
              emoji = '❌';
              statusMessage = 'Ваш заказ отменён';
              break;
            default:
              emoji = '📦';
              statusMessage = 'Статус заказа изменён';
          }

          // Отправляем уведомление клиенту
          await _notificationService.sendNotification(
            receiverId: userId,
            title: '$emoji Обновление заказа',
            body: statusMessage,
            type: 'order_status_update',
            data: {'status': newStatus},
          );
        }
      }
    } catch (e) {
      print('⚠️ Не удалось отправить уведомление клиенту: $e');
    }
  }

  Future<void> updatePaymentStatus(
    String orderId,
    String status,
    double paidAmount,
  ) async {
    // Get current order to check if there's remaining debt
    final orderDoc = await _firestore.collection('orders').doc(orderId).get();
    final orderData = orderDoc.data();

    if (orderData != null) {
      final totalAmount = (orderData['totalAmount'] ?? 0).toDouble();

      // Calculate remaining debt after this payment
      // If paidAmount equals totalAmount, then no debt remains
      final remainingDebt = totalAmount - paidAmount;

      await _firestore.collection('orders').doc(orderId).update({
        'paymentStatus': remainingDebt > 0 ? 'partial' : 'paid',
        'paidAmount': paidAmount,
        'debtAmount': remainingDebt > 0 ? remainingDebt : 0,
      });
    }
  }

  // Approve debt order - add debt to partner's account
  Future<void> approveDebtOrder(String orderId) async {
    try {
      // Get order details
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) {
        throw 'Order not found';
      }

      final orderData = orderDoc.data()!;
      final userId = orderData['userId'];
      final debtAmount = (orderData['debtAmount'] ?? 0).toDouble();

      if (userId == null || debtAmount <= 0) {
        throw 'Invalid order data';
      }

      // Add debt to partner's account
      await _debtService.updatePartnerDebt(userId, debtAmount);

      // Update order status
      await _firestore.collection('orders').doc(orderId).update({
        'isPendingApproval': false,
        'status': 'processing', // Move to processing after approval
      });

      // Notify partner
      await _notificationService.sendNotification(
        receiverId: userId,
        title: '✅ Заказ в долг одобрен',
        body:
            'Ваш заказ в долг на сумму ${debtAmount.toStringAsFixed(0)} ₸ одобрен',
        type: 'debt_order_approved',
        data: {'orderId': orderId},
      );
    } catch (e) {
      print('⚠️ Ошибка при одобрении заказа в долг: $e');
      rethrow;
    }
  }

  // Reject debt order
  Future<void> rejectDebtOrder(String orderId, {String? reason}) async {
    try {
      // Get order details
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) {
        throw 'Order not found';
      }

      final orderData = orderDoc.data()!;
      final userId = orderData['userId'];

      // Update order status to cancelled
      await _firestore.collection('orders').doc(orderId).update({
        'isPendingApproval': false,
        'status': 'cancelled',
      });

      // Notify partner
      if (userId != null) {
        await _notificationService.sendNotification(
          receiverId: userId,
          title: '❌ Заказ в долг отклонен',
          body: reason ?? 'Ваш заказ в долг был отклонен администратором',
          type: 'debt_order_rejected',
          data: {'orderId': orderId},
        );
      }
    } catch (e) {
      print('⚠️ Ошибка при отклонении заказа в долг: $e');
      rethrow;
    }
  }
}
