import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ailin_tattileri_app/core/models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final String _collection = 'products';

  // Get all products (Stream for real-time updates)
  Stream<List<Product>> getProducts() {
    // Safety: Limit load to 50 recent items to prevent UI freeze on startup
    return _firestore.collection(_collection).limit(50).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        return Product.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Add a new product
  Future<void> addProduct({
    required String name,
    required double price,
    required String description,
    required String category,
    required String imageUrl,
  }) async {
    try {
      // Save Data to Firestore
      await _firestore.collection(_collection).add({
        'name': name,
        'price': price,
        'description': description,
        'category': category,
        'imageUrl': imageUrl,
        'isAvailable': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error adding product: $e');
    }
  }

  // Update an existing product
  Future<void> updateProduct({
    required String id,
    required String name,
    required double price,
    required String description,
    required String category,
    required String imageUrl,
    bool? isAvailable,
  }) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'name': name,
        'price': price,
        'description': description,
        'category': category,
        'imageUrl': imageUrl,
        if (isAvailable != null) 'isAvailable': isAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating product: $e');
    }
  }

  // Toggle availability
  Future<void> toggleAvailability(String productId, bool currentStatus) async {
    await _firestore.collection(_collection).doc(productId).update({
      'isAvailable': !currentStatus,
    });
  }

  // Delete product
  Future<void> deleteProduct(String productId) async {
    await _firestore.collection(_collection).doc(productId).delete();
  }
}
