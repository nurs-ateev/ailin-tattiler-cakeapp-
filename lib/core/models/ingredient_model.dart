import 'package:cloud_firestore/cloud_firestore.dart';

class Ingredient {
  final String id;
  final String name;
  final String unit; // 'kg', 'l', 'pcs', 'g', 'ml'
  final double quantity;
  final double minQuantity;
  final double pricePerUnit; // Average or last purchase price
  final DateTime lastUpdated;

  Ingredient({
    required this.id,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.minQuantity,
    this.pricePerUnit = 0.0,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'unit': unit,
      'quantity': quantity,
      'minQuantity': minQuantity,
      'pricePerUnit': pricePerUnit,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  factory Ingredient.fromMap(Map<String, dynamic> map, String id) {
    return Ingredient(
      id: id,
      name: map['name'] ?? '',
      unit: map['unit'] ?? 'kg',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      minQuantity: (map['minQuantity'] as num?)?.toDouble() ?? 0.0,
      pricePerUnit: (map['pricePerUnit'] as num?)?.toDouble() ?? 0.0,
      lastUpdated:
          (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Helpers
  bool get isLowStock => quantity <= minQuantity;
}
