import 'dart:convert';
import 'package:ailin_tattileri_app/core/models/cart_item_model.dart';
import 'package:ailin_tattileri_app/core/models/return_item_model.dart';
import 'package:ailin_tattileri_app/core/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartService extends ChangeNotifier {
  final List<CartItem> _items = [];
  final List<ReturnItem> _returnItems = []; // Added return items
  bool _isDeliveryAvailable = true;
  String? _currentUserId; // Track current user

  List<CartItem> get items => _items;
  List<ReturnItem> get returnItems => _returnItems; // Added getter
  bool get isDeliveryAvailable => _isDeliveryAvailable;

  void setDeliveryAvailability(bool available) {
    _isDeliveryAvailable = available;
    notifyListeners();
  }

  double get subtotal => _items.fold(0, (sum, item) => sum + item.totalPrice);
  double get totalReturnAmount =>
      _returnItems.fold(0, (sum, item) => sum + item.totalPrice);
  double get totalAmount => subtotal - totalReturnAmount;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  int get returnCount =>
      _returnItems.fold(0, (sum, item) => sum + item.quantity);

  // Load cart for specific user
  Future<void> loadCart(String? userId) async {
    _currentUserId = userId;
    _items.clear();
    _returnItems.clear();

    final prefs = await SharedPreferences.getInstance();
    final key = userId != null ? 'cart_$userId' : 'cart_guest';
    final returnKey = userId != null ? 'returns_$userId' : 'returns_guest';

    final cartJson = prefs.getString(key);
    final returnsJson = prefs.getString(returnKey);

    if (cartJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(cartJson);
        for (var item in decoded) {
          _items.add(
            CartItem(
              product: Product.fromMap(item['product'], item['product']['id']),
              quantity: item['quantity'],
            ),
          );
        }
      } catch (e) {
        debugPrint('Error loading cart: $e');
      }
    }

    if (returnsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(returnsJson);
        for (var item in decoded) {
          _returnItems.add(ReturnItem.fromMap(item));
        }
      } catch (e) {
        debugPrint('Error loading returns: $e');
      }
    }
    notifyListeners();
  }

  // Save cart to SharedPreferences
  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _currentUserId != null ? 'cart_$_currentUserId' : 'cart_guest';
    final returnKey = _currentUserId != null
        ? 'returns_$_currentUserId'
        : 'returns_guest';

    final cartData = _items
        .map(
          (item) => {
            'product': item.product.toMap(),
            'quantity': item.quantity,
          },
        )
        .toList();

    final returnsData = _returnItems.map((item) => item.toMap()).toList();

    await prefs.setString(key, jsonEncode(cartData));
    await prefs.setString(returnKey, jsonEncode(returnsData));
  }

  void addItem(Product product, {int quantity = 1}) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      _items[index].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
    _saveCart();
    notifyListeners();
  }

  void addReturnItem(
    Product product, {
    int quantity = 1,
    String reason = 'expired',
  }) {
    final index = _returnItems.indexWhere(
      (item) => item.product.id == product.id && item.reason == reason,
    );
    if (index >= 0) {
      _returnItems[index].quantity += quantity;
    } else {
      _returnItems.add(
        ReturnItem(product: product, quantity: quantity, reason: reason),
      );
    }
    _saveCart();
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      _saveCart();
      notifyListeners();
    }
  }

  void removeSingleReturnItem(String productId, String reason) {
    final index = _returnItems.indexWhere(
      (item) => item.product.id == productId && item.reason == reason,
    );
    if (index >= 0) {
      if (_returnItems[index].quantity > 1) {
        _returnItems[index].quantity--;
      } else {
        _returnItems.removeAt(index);
      }
      _saveCart();
      notifyListeners();
    }
  }

  void removeItemCompletely(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    _saveCart();
    notifyListeners();
  }

  void removeReturnItemCompletely(String productId, String reason) {
    _returnItems.removeWhere(
      (item) => item.product.id == productId && item.reason == reason,
    );
    _saveCart();
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _returnItems.clear();
    _saveCart();
    notifyListeners();
  }
}
