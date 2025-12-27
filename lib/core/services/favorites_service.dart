import 'dart:convert';
import 'package:ailin_tattileri_app/core/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService extends ChangeNotifier {
  final List<Product> _favorites = [];
  String? _currentUserId;

  List<Product> get favorites => _favorites;

  int get count => _favorites.length;

  bool isFavorite(String productId) {
    return _favorites.any((p) => p.id == productId);
  }

  // Load favorites for specific user
  Future<void> loadFavorites(String? userId) async {
    _currentUserId = userId;
    _favorites.clear();

    final prefs = await SharedPreferences.getInstance();
    final key = userId != null ? 'favorites_$userId' : 'favorites_guest';
    final favoritesJson = prefs.getString(key);

    if (favoritesJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(favoritesJson);
        for (var item in decoded) {
          _favorites.add(Product.fromMap(item, item['id']));
        }
      } catch (e) {
        debugPrint('Error loading favorites: $e');
      }
    }
    notifyListeners();
  }

  // Save favorites to SharedPreferences
  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _currentUserId != null
        ? 'favorites_$_currentUserId'
        : 'favorites_guest';

    final favoritesData = _favorites.map((product) => product.toMap()).toList();
    await prefs.setString(key, jsonEncode(favoritesData));
  }

  // Toggle favorite (add if not exists, remove if exists)
  void toggleFavorite(Product product) {
    final index = _favorites.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      _favorites.removeAt(index);
    } else {
      _favorites.add(product);
    }
    _saveFavorites();
    notifyListeners();
  }

  // Remove from favorites
  void removeFavorite(String productId) {
    _favorites.removeWhere((p) => p.id == productId);
    _saveFavorites();
    notifyListeners();
  }

  // Clear all favorites
  void clearFavorites() {
    _favorites.clear();
    _saveFavorites();
    notifyListeners();
  }
}
