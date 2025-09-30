import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:goods_admin/data/models/product_model.dart';

class ProductRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _productsRef => _firestore.collection('products');

  Stream<List<Product>> getProducts() {
    return _productsRef.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>))
        .toList());
  }

  Future<List<Product>> getProductsList() async {
    final snapshot = await _productsRef.get();
    return snapshot.docs
        .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }
}
