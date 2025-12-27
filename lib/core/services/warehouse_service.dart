import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ailin_tattileri_app/core/models/ingredient_model.dart';

class WarehouseService {
  final CollectionReference _ingredientsRef = FirebaseFirestore.instance
      .collection('ingredients');
  final CollectionReference _transactionsRef = FirebaseFirestore.instance
      .collection('warehouse_transactions');

  // --- Ingredients CRUD ---

  Stream<List<Ingredient>> getIngredients() {
    return _ingredientsRef.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Ingredient.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> addIngredient(Ingredient ingredient) async {
    await _ingredientsRef.add(ingredient.toMap());
  }

  Future<void> updateIngredient(Ingredient ingredient) async {
    await _ingredientsRef.doc(ingredient.id).update(ingredient.toMap());
  }

  Future<void> deleteIngredient(String id) async {
    await _ingredientsRef.doc(id).delete();
  }

  // --- Stock Operations ---

  /// Add stock (Purchase/Incoming)
  Future<void> addStock({
    required String ingredientId,
    required double quantityToAdd,
    required double cost, // Total cost of this batch
    required String userId,
    String? note,
  }) async {
    return FirebaseFirestore.instance.runTransaction((transaction) async {
      final docRef = _ingredientsRef.doc(ingredientId);
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) throw Exception("Ingredient not found");

      final currentData = snapshot.data() as Map<String, dynamic>;
      final currentQty = (currentData['quantity'] as num).toDouble();

      // Calculate new weighted avg price if needed, strictly speaking simplified here:
      // letting client update pricePerUnit manually or keeping it as "last price".
      // Let's just update quantity for now.

      final newQty = currentQty + quantityToAdd;

      transaction.update(docRef, {
        'quantity': newQty,
        'lastUpdated': Timestamp.now(),
      });

      // Log Transaction
      final transactionRef = _transactionsRef.doc();
      transaction.set(transactionRef, {
        'ingredientId': ingredientId,
        'ingredientName': currentData['name'],
        'type': 'incoming',
        'quantity': quantityToAdd,
        'cost': cost,
        'userId': userId,
        'date': Timestamp.now(),
        'note': note,
      });
    });
  }

  /// Remove stock (Usage/Write-off)
  Future<void> removeStock({
    required String ingredientId,
    required double quantityToRemove,
    required String type, // 'usage', 'spoilage', 'correction'
    required String userId,
    String? note,
  }) async {
    return FirebaseFirestore.instance.runTransaction((transaction) async {
      final docRef = _ingredientsRef.doc(ingredientId);
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) throw Exception("Ingredient not found");

      final currentData = snapshot.data() as Map<String, dynamic>;
      final currentQty = (currentData['quantity'] as num).toDouble();
      final newQty = currentQty - quantityToRemove;

      if (newQty < 0) {
        // Option: allow negative stock or throw error. Usually warn but allow?
        // Let's allow for now but typically UI should prevent.
      }

      transaction.update(docRef, {
        'quantity': newQty,
        'lastUpdated': Timestamp.now(),
      });

      // Log Transaction
      final transactionRef = _transactionsRef.doc();
      transaction.set(transactionRef, {
        'ingredientId': ingredientId,
        'ingredientName': currentData['name'],
        'type': type,
        'quantity': quantityToRemove,
        'userId': userId,
        'date': Timestamp.now(),
        'note': note,
      });
    });
  }
}
