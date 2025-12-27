import 'package:cloud_firestore/cloud_firestore.dart';

class Worker {
  final String id;
  final String name;
  final String position; // Должность (например, "Повар", "Курьер")
  final String phone;
  final double hourlyRate; // Ставка за час (₸)
  final String? userId; // ID пользователя (для входа работника)
  final String? fcmToken; // FCM Push Token
  final double balance; // Unpaid accumulated salary
  final String? invitedEmail; // Email created by admin
  final String? invitedPassword; // Password created by admin
  final DateTime createdAt;

  Worker({
    required this.id,
    required this.name,
    required this.position,
    required this.phone,
    this.hourlyRate = 0,
    this.userId,
    this.fcmToken,
    this.balance = 0.0,
    this.invitedEmail,
    this.invitedPassword,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'position': position,
      'phone': phone,
      'hourlyRate': hourlyRate,
      'userId': userId,
      'fcmToken': fcmToken,
      'balance': balance,
      'invitedEmail': invitedEmail,
      'invitedPassword': invitedPassword,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Worker.fromMap(Map<String, dynamic> map, String documentId) {
    return Worker(
      id: documentId,
      name: map['name'] ?? '',
      position: map['position'] ?? '',
      phone: map['phone'] ?? '',
      hourlyRate: (map['hourlyRate'] ?? 0).toDouble(),
      userId: map['userId'],
      fcmToken: map['fcmToken'],
      balance: (map['balance'] ?? 0).toDouble(),
      invitedEmail: map['invitedEmail'],
      invitedPassword: map['invitedPassword'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
