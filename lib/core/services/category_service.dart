import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ailin_tattileri_app/core/models/category_model.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'categories';

  Stream<List<CategoryModel>> getCategories() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return CategoryModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> addCategory({
    required String nameRu,
    required String nameKk,
    required String icon,
  }) async {
    await _firestore.collection(_collection).add({
      'nameRu': nameRu,
      'nameKk': nameKk,
      'icon': icon,
    });
  }

  Future<void> updateCategory({
    required String id,
    required String nameRu,
    required String nameKk,
    required String icon,
  }) async {
    await _firestore.collection(_collection).doc(id).update({
      'nameRu': nameRu,
      'nameKk': nameKk,
      'icon': icon,
    });
  }

  Future<void> deleteCategory(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }
}
