import 'package:cloud_firestore/cloud_firestore.dart';

class PartnerModel {
  final String id;
  final String name; // Name of the store/venue
  final String contactPerson;
  final String phone;
  final String? userId; // Link to the user account
  final String? invitedEmail;
  final String? invitedPassword;
  final DateTime createdAt;
  final double totalDebt; // Total debt amount

  PartnerModel({
    required this.id,
    required this.name,
    required this.contactPerson,
    required this.phone,
    this.userId,
    this.invitedEmail,
    this.invitedPassword,
    required this.createdAt,
    this.totalDebt = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'contactPerson': contactPerson,
      'phone': phone,
      'userId': userId,
      'invitedEmail': invitedEmail,
      'invitedPassword': invitedPassword,
      'createdAt': Timestamp.fromDate(createdAt),
      'totalDebt': totalDebt,
    };
  }

  factory PartnerModel.fromMap(Map<String, dynamic> map, String id) {
    return PartnerModel(
      id: id,
      name: map['name'] ?? '',
      contactPerson: map['contactPerson'] ?? '',
      phone: map['phone'] ?? '',
      userId: map['userId'],
      invitedEmail: map['invitedEmail'],
      invitedPassword: map['invitedPassword'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      totalDebt: (map['totalDebt'] ?? 0).toDouble(),
    );
  }
}
