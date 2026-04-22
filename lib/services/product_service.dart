import 'package:cloud_firestore/cloud_firestore.dart';

class ProductService {
  final CollectionReference _productsCollection = FirebaseFirestore.instance
      .collection('products');

  /// Obtener todos los productos en tiempo real
  Stream<List<Map<String, dynamic>>> getAllProducts() {
    return _productsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Obtener productos por categoría
  Stream<List<Map<String, dynamic>>> getProductsByCategory(String category) {
    return _productsCollection
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  /// Obtener todos los productos una vez (para búsqueda global)
  Future<List<Map<String, dynamic>>> getAllProductsOnce() async {
    final snapshot = await _productsCollection.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Agregar producto
  Future<void> addProduct(Map<String, dynamic> productData) {
    return _productsCollection.add(productData);
  }

  /// Actualizar producto
  Future<void> updateProduct(String id, Map<String, dynamic> newData) {
    return _productsCollection.doc(id).update(newData);
  }

  /// Eliminar producto
  Future<void> deleteProduct(String id) {
    return _productsCollection.doc(id).delete();
  }
}
