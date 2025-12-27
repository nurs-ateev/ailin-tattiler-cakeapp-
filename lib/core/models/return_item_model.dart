import 'package:ailin_tattileri_app/core/models/product_model.dart';

class ReturnItem {
  final Product product;
  int quantity;
  String reason; // 'expired', 'unsold', 'damaged'

  ReturnItem({
    required this.product,
    this.quantity = 1,
    this.reason = 'expired',
  });

  double get totalPrice => product.price * quantity;

  Map<String, dynamic> toMap() {
    return {'product': product.toMap(), 'quantity': quantity, 'reason': reason};
  }

  factory ReturnItem.fromMap(Map<String, dynamic> map) {
    return ReturnItem(
      product: Product.fromMap(map['product'], map['product']['id']),
      quantity: map['quantity'],
      reason: map['reason'] ?? 'expired',
    );
  }
}
