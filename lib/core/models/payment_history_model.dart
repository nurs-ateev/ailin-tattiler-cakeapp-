import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentHistoryModel {
  final String id;
  final String orderId;
  final String partnerId;
  final double amount;
  final String type; // 'admin_payment', 'partner_request', 'admin_approved'
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;
  final String? adminId;
  final String? note;

  PaymentHistoryModel({
    required this.id,
    required this.orderId,
    required this.partnerId,
    required this.amount,
    required this.type,
    this.status = 'approved',
    required this.createdAt,
    this.adminId,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'partnerId': partnerId,
      'amount': amount,
      'type': type,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'adminId': adminId,
      'note': note,
    };
  }

  factory PaymentHistoryModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentHistoryModel(
      id: id,
      orderId: map['orderId'] ?? '',
      partnerId: map['partnerId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      type: map['type'] ?? 'admin_payment',
      status: map['status'] ?? 'approved',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      adminId: map['adminId'],
      note: map['note'],
    );
  }
}
