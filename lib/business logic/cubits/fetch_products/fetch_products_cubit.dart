import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:goods_admin/data/models/product_model.dart';
import 'package:meta/meta.dart';

part 'fetch_products_state.dart';

class FetchProductsCubit extends Cubit<FetchProductsState> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<Product> _cachedProducts = [];

  FetchProductsCubit() : super(FetchProductsInitial());

  Future<void> fetchProducts() async {
    try {
      emit(FetchProductsLoading());
      QuerySnapshot snapshot = await firestore.collection('products').get();

      List<Product> products = snapshot.docs
          .map((e) => Product.fromMap(e.data() as Map<String, dynamic>))
          .toList();

      _cachedProducts = products;
      emit(FetchProductsLoaded(products));
    } catch (e) {
      emit(FetchProductsError(e.toString()));
    }
  }

  void updateProductInList(Product updatedProduct) {
    if (state is FetchProductsLoaded) {
      final currentProducts = (state as FetchProductsLoaded).products;
      final updatedProducts = currentProducts.map((product) {
        if (product.productId == updatedProduct.productId) {
          return updatedProduct;
        }
        return product;
      }).toList();

      _cachedProducts = updatedProducts;
      emit(FetchProductsLoaded(updatedProducts));
    }
  }

  void removeProductFromList(String productId) {
    if (state is FetchProductsLoaded) {
      final currentProducts = (state as FetchProductsLoaded).products;
      final updatedProducts = currentProducts
          .where((product) => product.productId != productId)
          .toList();

      _cachedProducts = updatedProducts;
      emit(FetchProductsLoaded(updatedProducts));
    }
  }

  void addProductToList(Product newProduct) {
    if (state is FetchProductsLoaded) {
      final currentProducts = (state as FetchProductsLoaded).products;
      final updatedProducts = [newProduct, ...currentProducts];

      _cachedProducts = updatedProducts;
      emit(FetchProductsLoaded(updatedProducts));
    }
  }

  List<Product> get cachedProducts => _cachedProducts;

  List<Product> searchInCachedProducts(String query) {
    if (query.isEmpty) return _cachedProducts;

    return _cachedProducts
        .where((product) =>
            product.name.toLowerCase().contains(query.toLowerCase()) ||
            product.manufacturer.toLowerCase().contains(query.toLowerCase()) ||
            product.classification.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
