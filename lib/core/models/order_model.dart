import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String? userId; // Added userId
  final String userName;
  final String userPhone;
  final String userAddress;
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>>? returnItems; // Added returnItems
  final double totalAmount;
  final double refundAmount; // Added refundAmount
  final String status;
  final String deliveryType; // 'delivery' or 'pickup'
  final DateTime createdAt;
  final String orderType; // 'online' or 'walk_in'

  // Payment fields
  final String paymentStatus; // 'paid', 'unpaid', 'partial'
  final double paidAmount; // Amount already paid
  final double debtAmount; // Remaining debt

  // Additional fields
  final String? deliveryTime; // Preferred delivery time
  final String? comment; // Order comment
  final bool isPendingApproval; // For debt orders waiting admin approval
  final String?
  orderNumber; // Human-readable order number (P-25-0001 or K-25-0001)

  OrderModel({
    required this.id,
    this.userId,
    required this.userName,
    required this.userPhone,
    required this.userAddress,
    required this.items,
    this.returnItems,
    required this.totalAmount,
    this.refundAmount = 0.0,
    required this.status,
    this.deliveryType = 'delivery', // Default to delivery
    required this.createdAt,
    this.orderType = 'online', // Default to online
    this.paymentStatus = 'paid', // Default to paid
    this.paidAmount = 0.0,
    this.debtAmount = 0.0,
    this.deliveryTime,
    this.comment,
    this.isPendingApproval = false, // Default to false
    this.orderNumber,
  });

  OrderModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhone,
    String? userAddress,
    List<Map<String, dynamic>>? items,
    List<Map<String, dynamic>>? returnItems,
    double? totalAmount,
    double? refundAmount,
    String? status,
    String? deliveryType,
    DateTime? createdAt,
    String? orderType,
    String? paymentStatus,
    double? paidAmount,
    double? debtAmount,
    String? deliveryTime,
    String? comment,
    bool? isPendingApproval,
    String? orderNumber,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      userAddress: userAddress ?? this.userAddress,
      items: items ?? this.items,
      returnItems: returnItems ?? this.returnItems,
      totalAmount: totalAmount ?? this.totalAmount,
      refundAmount: refundAmount ?? this.refundAmount,
      status: status ?? this.status,
      deliveryType: deliveryType ?? this.deliveryType,
      createdAt: createdAt ?? this.createdAt,
      orderType: orderType ?? this.orderType,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paidAmount: paidAmount ?? this.paidAmount,
      debtAmount: debtAmount ?? this.debtAmount,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      comment: comment ?? this.comment,
      isPendingApproval: isPendingApproval ?? this.isPendingApproval,
      orderNumber: orderNumber ?? this.orderNumber,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'userAddress': userAddress,
      'items': items,
      'returnItems': returnItems,
      'totalAmount': totalAmount,
      'refundAmount': refundAmount,
      'status': status,
      'deliveryType': deliveryType,
      'createdAt': Timestamp.fromDate(createdAt),
      'orderType': orderType,
      'paymentStatus': paymentStatus,
      'paidAmount': paidAmount,
      'debtAmount': debtAmount,
      'deliveryTime': deliveryTime,
      'comment': comment,
      'isPendingApproval': isPendingApproval,
      'orderNumber': orderNumber,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, String documentId) {
    return OrderModel(
      id: documentId,
      userId: map['userId'],
      userName: map['userName'] ?? '',
      userPhone: map['userPhone'] ?? '',
      userAddress: map['userAddress'] ?? '',
      items: List<Map<String, dynamic>>.from(map['items'] ?? []),
      returnItems: map['returnItems'] != null
          ? List<Map<String, dynamic>>.from(map['returnItems'])
          : null,
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      refundAmount: (map['refundAmount'] ?? 0).toDouble(),
      status: map['status'] ?? 'new',
      deliveryType: map['deliveryType'] ?? 'delivery',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      orderType: map['orderType'] ?? 'online',
      paymentStatus: map['paymentStatus'] ?? 'paid',
      paidAmount: (map['paidAmount'] ?? 0).toDouble(),
      debtAmount: (map['debtAmount'] ?? 0).toDouble(),
      deliveryTime: map['deliveryTime'],
      comment: map['comment'],
      isPendingApproval: map['isPendingApproval'] ?? false,
      orderNumber: map['orderNumber'],
    );
  }
}
