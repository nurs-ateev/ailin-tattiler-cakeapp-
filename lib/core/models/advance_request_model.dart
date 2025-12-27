import 'package:cloud_firestore/cloud_firestore.dart';

class AdvanceRequest {
  final String id;
  final String workerId;
  final String workerName;
  final double amount;
  final DateTime requestDate;
  final String status; // 'pending', 'accepted', 'rejected'
  final String? note;
  final String? adminId;

  AdvanceRequest({
    required this.id,
    required this.workerId,
    required this.workerName,
    required this.amount,
    required this.requestDate,
    required this.status,
    this.note,
    this.adminId,
  });

  factory AdvanceRequest.fromMap(Map<String, dynamic> map, String id) {
    return AdvanceRequest(
      id: id,
      workerId: map['workerId'] ?? '',
      workerName: map['workerName'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      requestDate: (map['requestDate'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
      note: map['note'],
      adminId: map['adminId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'workerId': workerId,
      'workerName': workerName,
      'amount': amount,
      'requestDate': Timestamp.fromDate(requestDate),
      'status': status,
      'note': note,
      'adminId': adminId,
      'receiverId': adminId ?? 'admin',
    };
  }
}
